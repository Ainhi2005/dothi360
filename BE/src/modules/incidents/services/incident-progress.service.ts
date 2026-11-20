import { normalizeMedia, type UploadedMedia } from "../incident-media";
import { IsNull } from "typeorm";
import { AppDataSource } from "../../../database/data-source";
import { Incident } from "../incident.entity";

import { IncidentMedia } from "../../media/media.entity";

import { IncidentAssignment } from "../../assignments/assignment.entity";
import { IncidentUpdate } from "../../incident-updates/incident-update.entity";

import {
  canOfficerTransitionIncident,
  canTransitionIncident,
} from "../../../common/constants/incident-status";

import { IncidentServiceDependencies } from "./incident-dependencies";
import { IncidentQueryService } from "./incident-query.service";

/** Cập nhật trạng thái và tiến độ của cán bộ. */
export class IncidentProgressService {
  constructor(
    private readonly deps: IncidentServiceDependencies,
    private readonly query: Pick<IncidentQueryService, "findOne">,
  ) {}

  async updateStatus(
    id: string,
    userId: string,
    role: string,
    departmentId: string | null,
    data: any,
  ) {
    const { status, note, media_urls } = data;
    const updateLog = await AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const updateRepo = manager.getRepository(IncidentUpdate);
      const mediaRepo = manager.getRepository(IncidentMedia);
      const incident = await incidentRepo.findOne({
        where: { id },
        lock: { mode: "pessimistic_write" },
      });
      if (!incident) throw { statusCode: 404, message: "Không tìm thấy sự cố" };

      if (role === "OFFICER") {
        let assignment = await assignmentRepo.findOne({
          where: { incident_id: id, accepted_by: userId, ended_at: IsNull() },
          lock: { mode: "pessimistic_write" },
        });
        if (!assignment && departmentId) {
          const deptAssignment = await assignmentRepo.findOne({
            where: {
              incident_id: id,
              department_id: departmentId,
              accepted_by: IsNull(),
              ended_at: IsNull(),
            },
            lock: { mode: "pessimistic_write" },
          });
          if (deptAssignment) {
            deptAssignment.accepted_by = userId;
            deptAssignment.accepted_at = new Date();
            assignment = await assignmentRepo.save(deptAssignment);
          }
        }
        if (!assignment || assignment.department_id !== departmentId) {
          throw {
            statusCode: 403,
            message: "Bạn phải tiếp nhận nhiệm vụ này trước khi cập nhật",
          };
        }
        if (!assignment.accepted_at) {
          assignment.accepted_at = new Date();
          await assignmentRepo.save(assignment);
        }
      }
      if (!canTransitionIncident(incident.status, status)) {
        throw {
          statusCode: 409,
          message: `Không thể chuyển từ ${incident.status} sang ${status}`,
        };
      }
      if (
        role === "OFFICER" &&
        !canOfficerTransitionIncident(incident.status, status)
      ) {
        throw {
          statusCode: 403,
          message:
            "Cán bộ chỉ được chuyển sang đang xử lý hoặc hoàn thành theo đúng quy trình",
        };
      }
      if (role === "OFFICER" && status === "PENDING_VERIFICATION") {
        const [missing] = await manager.query(
          `SELECT COUNT(*)::int count FROM incident_type_checklist_items c LEFT JOIN incident_checklist_results r ON r.checklist_item_id=c.id AND r.incident_id=$1 WHERE c.incident_type_id=$2 AND c.is_active=TRUE AND c.is_required=TRUE AND COALESCE(r.completed,FALSE)=FALSE`,
          [id, incident.incident_type_id],
        );
        if (Number(missing?.count ?? 0) > 0) {
          throw {
            statusCode: 409,
            message: `Còn ${missing.count} bước checklist bắt buộc chưa hoàn thành`,
          };
        }
      }

      const oldStatus = incident.status;
      incident.status = status;
      incident.resolved_at = status === "RESOLVED" ? new Date() : null;
      await incidentRepo.save(incident);

      if (["RESOLVED", "REJECTED", "CANCELLED"].includes(status)) {
        await assignmentRepo.update(
          { incident_id: id, ended_at: IsNull() },
          { ended_at: new Date() },
        );
      }

      const savedLog = await updateRepo.save(
        updateRepo.create({
          incident_id: id,
          updated_by: userId,
          old_status: oldStatus,
          new_status: status,
          note,
        }),
      );
      const statusLabel: Record<string, string> = {
        IN_PROGRESS: "đang xử lý",
        PENDING_VERIFICATION: "đang chờ nghiệm thu",
        RESOLVED: "đã hoàn thành",
        REJECTED: "đã bị từ chối",
        CANCELLED: "đã bị hủy",
      };
      const reason = ["REJECTED", "CANCELLED"].includes(status)
        ? ` Lý do: ${note}`
        : "";
      await this.deps.notificationService.notifyReporters(
        id,
        `STATUS_${status}`,
        "Trạng thái phản ánh đã thay đổi",
        `Phản ánh của bạn ${statusLabel[status] ?? status}.${reason}`,
        manager,
      );
      if (media_urls?.length) {
        await mediaRepo.save(
          media_urls.map((raw: string | UploadedMedia) => {
            const media = normalizeMedia(raw);
            return mediaRepo.create({
              incident_id: id,
              update_id: savedLog.id,
              uploaded_by: userId,
              media_type: media.type.startsWith("video/") ? "VIDEO" : "IMAGE",
              file_url: media.url,
              storage_key: media.storage_key,
              mime_type: media.type,
              file_size: media.size,
            });
          }),
        );
      }
      if (status === "PENDING_VERIFICATION") {
        await this.deps.notificationService.notifyAdmins(
          {
            eventKey: `verification:${savedLog.id}`,
            type: "INCIDENT_PENDING_VERIFICATION",
            incidentId: id,
            title: "Có hồ sơ chờ nghiệm thu",
            message: `Cán bộ đã gửi kết quả xử lý: ${String(note ?? "").slice(0, 180)}`,
            actionPath: `/incidents/${id}`,
            actionLabel: "Mở nghiệm thu",
            data: { update_id: savedLog.id, status },
          },
          manager,
        );
      }
      return savedLog;
    });

    return { incident: await this.query.findOne(id), updateLog };
  }

  async addProgressUpdate(
    id: string,
    officerId: string,
    departmentId: string | null,
    data: {
      note: string;
      media_urls?: Array<string | UploadedMedia>;
      progress_percent: number;
      estimated_completion_at?: string;
      blocker?: string;
      visibility: "PUBLIC" | "INTERNAL";
    },
  ) {
    const savedLog = await AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const updateRepo = manager.getRepository(IncidentUpdate);
      const mediaRepo = manager.getRepository(IncidentMedia);
      const incident = await incidentRepo.findOne({
        where: { id },
        lock: { mode: "pessimistic_read" },
      });
      if (!incident) throw { statusCode: 404, message: "Không tìm thấy sự cố" };
      if (incident.status !== "IN_PROGRESS") {
        throw {
          statusCode: 409,
          message: "Chỉ có thể báo cáo tiến độ khi sự cố đang được xử lý",
        };
      }
      const assignment = await assignmentRepo.findOne({
        where: { incident_id: id, accepted_by: officerId, ended_at: IsNull() },
      });
      if (!assignment || assignment.department_id !== departmentId) {
        throw {
          statusCode: 403,
          message: "Bạn không phải cán bộ đang phụ trách nhiệm vụ này",
        };
      }
      const update = await updateRepo.save(
        updateRepo.create({
          incident_id: id,
          updated_by: officerId,
          old_status: "IN_PROGRESS",
          new_status: "IN_PROGRESS",
          note: data.note,
          progress_percent: data.progress_percent,
          estimated_completion_at: data.estimated_completion_at
            ? new Date(data.estimated_completion_at)
            : null,
          blocker: data.blocker?.trim() || null,
          visibility: data.visibility,
        }),
      );
      if (data.media_urls?.length) {
        await mediaRepo.save(
          data.media_urls.map((raw) => {
            const media = normalizeMedia(raw);
            return mediaRepo.create({
              incident_id: id,
              update_id: update.id,
              uploaded_by: officerId,
              media_type: media.type.startsWith("video/") ? "VIDEO" : "IMAGE",
              file_url: media.url,
              storage_key: media.storage_key,
              mime_type: media.type,
              file_size: media.size,
            });
          }),
        );
      }
      if (data.blocker?.trim()) {
        const [previous] = await manager.query(
          "SELECT blocker FROM incident_updates WHERE incident_id=$1 AND id<>$2 ORDER BY created_at DESC LIMIT 1",
          [id, update.id],
        );
        if (previous?.blocker?.trim() !== data.blocker.trim()) {
          await this.deps.notificationService.notifyAdmins(
            {
              eventKey: `blocker:${update.id}`,
              type: "INCIDENT_BLOCKED",
              incidentId: id,
              title: "Cán bộ báo khó khăn cần xem xét",
              message: data.blocker.trim().slice(0, 500),
              actionPath: `/incidents/${id}`,
              actionLabel: "Xem và điều phối",
              data: { update_id: update.id },
            },
            manager,
          );
        }
      }
      if (data.visibility === "PUBLIC") {
        await this.deps.notificationService.notifyReporters(
          id,
          "PROGRESS_UPDATED",
          "Có cập nhật tiến độ mới",
          data.note,
          manager,
        );
      }
      return update;
    });
    return { update: savedLog, incident: await this.query.findOne(id) };
  }
}
