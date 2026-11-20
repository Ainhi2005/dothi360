import { AppDataSource } from "../../../database/data-source";
import { IncidentAssignment } from "../assignment.entity";
import { Incident } from "../../incidents/incident.entity";
import { IncidentUpdate } from "../../incident-updates/incident-update.entity";
import { IsNull } from "typeorm";
import { NotificationService } from "../../notifications/notification.service";
import { AuditLogService } from "../../audit-logs/audit-log.service";

import { AssignmentServiceDependencies } from "./assignment-dependencies";

/** Tiếp nhận hoặc từ chối công việc. */
export class AssignmentResponseService {
  constructor(private readonly deps: AssignmentServiceDependencies) {}

  async acceptAssignment(
    assignmentId: string,
    userId: string,
    departmentId: string,
  ) {
    return AppDataSource.transaction(async (manager) => {
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const incidentRepo = manager.getRepository(Incident);
      const updateRepo = manager.getRepository(IncidentUpdate);
      const assignment = await assignmentRepo.findOne({
        where: { id: assignmentId, ended_at: IsNull() },
        lock: { mode: "pessimistic_write" },
      });
      if (!assignment)
        throw {
          statusCode: 404,
          message: "Không tìm thấy phân công hoặc đã kết thúc",
        };
      if (assignment.department_id !== departmentId) {
        throw {
          statusCode: 403,
          message: "Bạn không thuộc đơn vị được phân công",
        };
      }
      if (assignment.accepted_by) {
        throw {
          statusCode: 409,
          message: "Sự cố này đã được tiếp nhận bởi người khác",
        };
      }
      if (
        assignment.assigned_officer_id &&
        assignment.assigned_officer_id !== userId
      ) {
        throw {
          statusCode: 403,
          message: "Nhiệm vụ này được chỉ định cho cán bộ khác",
        };
      }

      assignment.accepted_by = userId;
      assignment.accepted_at = new Date();
      await assignmentRepo.save(assignment);

      const incident = await incidentRepo.findOne({
        where: { id: assignment.incident_id },
        lock: { mode: "pessimistic_write" },
      });
      if (!incident)
        throw { statusCode: 404, message: "Sự cố không còn tồn tại" };
      const oldStatus = incident.status;
      if (oldStatus !== "ASSIGNED") {
        throw {
          statusCode: 409,
          message: `Không thể tiếp nhận sự cố ở trạng thái ${oldStatus}`,
        };
      }
      incident.status = "ACCEPTED";
      await incidentRepo.save(incident);
      await updateRepo.save(
        updateRepo.create({
          incident_id: incident.id,
          updated_by: userId,
          old_status: oldStatus,
          new_status: "ACCEPTED",
          note: "Cán bộ đã tiếp nhận xử lý",
        }),
      );
      await new NotificationService().notifyReporters(
        incident.id,
        "ASSIGNMENT_ACCEPTED",
        "Sự cố đã được tiếp nhận",
        "Cán bộ xử lý đã tiếp nhận phản ánh của bạn.",
        manager,
      );
      return assignment;
    });
  }

  async rejectAssignment(
    assignmentId: string,
    userId: string,
    departmentId: string,
    data: { reason_code: string; reason: string },
  ) {
    return AppDataSource.transaction(async (manager) => {
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const incidentRepo = manager.getRepository(Incident);
      const updateRepo = manager.getRepository(IncidentUpdate);
      const assignment = await assignmentRepo.findOne({
        where: { id: assignmentId, ended_at: IsNull() },
        lock: { mode: "pessimistic_write" },
      });
      if (!assignment)
        throw { statusCode: 404, message: "Phân công không còn hiệu lực" };
      if (assignment.department_id !== departmentId) {
        throw {
          statusCode: 403,
          message: "Bạn không thuộc đơn vị được phân công",
        };
      }
      if (assignment.accepted_by) {
        throw {
          statusCode: 409,
          message:
            "Nhiệm vụ đã được tiếp nhận. Hãy dùng Báo cáo trở ngại để yêu cầu điều phối.",
        };
      }
      if (
        assignment.assigned_officer_id &&
        assignment.assigned_officer_id !== userId
      ) {
        throw {
          statusCode: 403,
          message: "Bạn không phải cán bộ được chỉ định cho nhiệm vụ này",
        };
      }

      const incident = await incidentRepo.findOne({
        where: { id: assignment.incident_id },
        lock: { mode: "pessimistic_write" },
      });
      if (!incident)
        throw { statusCode: 404, message: "Sự cố không còn tồn tại" };
      if (incident.status !== "ASSIGNED") {
        throw {
          statusCode: 409,
          message: `Không thể từ chối hồ sơ ở trạng thái ${incident.status}`,
        };
      }

      const now = new Date();
      assignment.ended_at = now;
      assignment.rejected_by = userId;
      assignment.rejection_code = data.reason_code;
      assignment.rejection_reason = data.reason.trim();
      assignment.rejected_at = now;
      await assignmentRepo.save(assignment);

      const oldStatus = incident.status;
      incident.status = "PENDING_ASSIGNMENT";
      incident.ai_suggested_department_id = null;
      incident.ai_suggested_officer_id = null;
      await incidentRepo.save(incident);
      await updateRepo.save(
        updateRepo.create({
          incident_id: incident.id,
          updated_by: userId,
          old_status: oldStatus,
          new_status: "PENDING_ASSIGNMENT",
          note: `Đang điều phối lại. Lý do: ${data.reason.trim()}`,
          visibility: "PUBLIC",
        }),
      );

      const notifications = new NotificationService();
      await notifications.notifyReporters(
        incident.id,
        "ASSIGNMENT_REALLOCATION",
        "Hồ sơ đang được điều phối lại",
        `Đơn vị tiếp nhận chưa phù hợp. Hệ thống đang chuyển hồ sơ tới đơn vị khác. Lý do: ${data.reason.trim()}`,
        manager,
      );
      await notifications.notifyAdmins(
        {
          eventKey: `assignment-rejected:${assignment.id}`,
          type: "ASSIGNMENT_REJECTED",
          incidentId: incident.id,
          title: "Nhiệm vụ cần điều phối lại",
          message: data.reason.trim(),
          actionPath: `/incidents/${incident.id}`,
          actionLabel: "Phân công lại",
          data: { assignment_id: assignment.id, reason_code: data.reason_code },
        },
        manager,
      );
      await new AuditLogService().record(
        {
          user_id: userId,
          action: "ASSIGNMENT_REJECTED",
          entity_type: "incident_assignment",
          entity_id: assignment.id,
          details: {
            incident_id: incident.id,
            department_id: departmentId,
            reason_code: data.reason_code,
            reason: data.reason.trim(),
          },
        },
        manager,
      );
      return {
        assignment_id: assignment.id,
        incident_id: incident.id,
        status: incident.status,
      };
    });
  }
}
