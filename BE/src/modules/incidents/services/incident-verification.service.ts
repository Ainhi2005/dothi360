import { IsNull } from "typeorm";
import { AppDataSource } from "../../../database/data-source";
import { Incident } from "../incident.entity";

import { IncidentAssignment } from "../../assignments/assignment.entity";
import { IncidentUpdate } from "../../incident-updates/incident-update.entity";

import { IncidentServiceDependencies } from "./incident-dependencies";
import { IncidentQueryService } from "./incident-query.service";

/** Admin nghiệm thu hoặc yêu cầu làm lại. */
export class IncidentVerificationService {
  constructor(
    private readonly deps: IncidentServiceDependencies,
    private readonly query: Pick<IncidentQueryService, "findOne">,
  ) {}

  async verifyIncident(
    id: string,
    adminId: string,
    data: { decision: "APPROVE" | "REWORK"; note: string },
  ) {
    await AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const updateRepo = manager.getRepository(IncidentUpdate);
      const incident = await incidentRepo.findOne({
        where: { id },
        lock: { mode: "pessimistic_write" },
      });
      if (!incident) throw { statusCode: 404, message: "Không tìm thấy sự cố" };
      if (incident.status !== "PENDING_VERIFICATION") {
        throw {
          statusCode: 409,
          message: "Sự cố chưa ở trạng thái chờ nghiệm thu",
        };
      }
      const assignment = await assignmentRepo.findOne({
        where: { incident_id: id, ended_at: IsNull() },
        lock: { mode: "pessimistic_write" },
      });
      const nextStatus =
        data.decision === "APPROVE" ? "RESOLVED" : "IN_PROGRESS";
      incident.status = nextStatus;
      incident.resolved_at = nextStatus === "RESOLVED" ? new Date() : null;
      await incidentRepo.save(incident);
      if (nextStatus === "RESOLVED") {
        await assignmentRepo.update(
          { incident_id: id, ended_at: IsNull() },
          { ended_at: new Date() },
        );
      }
      await updateRepo.save(
        updateRepo.create({
          incident_id: id,
          updated_by: adminId,
          old_status: "PENDING_VERIFICATION",
          new_status: nextStatus,
          note: data.note,
        }),
      );
      await this.deps.auditLogService.record(
        {
          user_id: adminId,
          action:
            data.decision === "APPROVE"
              ? "INCIDENT_VERIFIED"
              : "INCIDENT_REWORK_REQUESTED",
          entity_type: "incident",
          entity_id: id,
          details: {
            note: data.note,
            officer_id: assignment?.accepted_by ?? null,
          },
        },
        manager,
      );
      if (assignment?.accepted_by) {
        await this.deps.notificationService.create(
          {
            user_id: assignment.accepted_by,
            incident_id: id,
            type:
              data.decision === "APPROVE"
                ? "WORK_VERIFIED"
                : "WORK_REWORK_REQUIRED",
            title:
              data.decision === "APPROVE"
                ? "Kết quả đã được nghiệm thu"
                : "Yêu cầu xử lý bổ sung",
            message: data.note,
            data: { incident_id: id, assignment_id: assignment.id },
          },
          manager,
        );
      }
      await this.deps.notificationService.notifyReporters(
        id,
        `STATUS_${nextStatus}`,
        data.decision === "APPROVE"
          ? "Sự cố đã hoàn thành"
          : "Sự cố đang được xử lý bổ sung",
        data.note,
        manager,
      );
    });
    return this.query.findOne(id);
  }
}
