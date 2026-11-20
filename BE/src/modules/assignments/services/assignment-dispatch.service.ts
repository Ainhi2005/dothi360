import { AppDataSource } from "../../../database/data-source";
import { IncidentAssignment } from "../assignment.entity";
import { Incident } from "../../incidents/incident.entity";
import { IncidentUpdate } from "../../incident-updates/incident-update.entity";
import { IsNull } from "typeorm";
import { NotificationService } from "../../notifications/notification.service";
import { AuditLogService } from "../../audit-logs/audit-log.service";
import { DepartmentAssignmentService } from "../../../algorithms/department-assignment/department-assignment.service";

import { AssignmentServiceDependencies } from "./assignment-dependencies";

/** Phân công, giao lại và duyệt gợi ý phân công. */
export class AssignmentDispatchService {
  constructor(private readonly deps: AssignmentServiceDependencies) {}

  async reassign(data: any, adminId: string) {
    const { incident_id, new_department_id, reason } = data;
    return AppDataSource.transaction(async (manager) => {
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const incidentRepo = manager.getRepository(Incident);
      const updateRepo = manager.getRepository(IncidentUpdate);
      const incident = await incidentRepo.findOne({
        where: { id: incident_id },
        lock: { mode: "pessimistic_write" },
      });
      if (!incident) throw { statusCode: 404, message: "Không tìm thấy sự cố" };
      if (["RESOLVED", "REJECTED", "CANCELLED"].includes(incident.status)) {
        throw {
          statusCode: 409,
          message: "Không thể phân công hồ sơ đã kết thúc",
        };
      }

      const departmentExists = await manager.query(
        "SELECT 1 FROM departments WHERE id = $1 AND is_active = TRUE",
        [new_department_id],
      );
      if (!departmentExists.length)
        throw {
          statusCode: 400,
          message: "Đơn vị mới không tồn tại hoặc đã ngừng hoạt động",
        };

      const oldAssignment = await assignmentRepo.findOne({
        where: { incident_id, ended_at: IsNull() },
        lock: { mode: "pessimistic_write" },
      });
      if (oldAssignment) {
        oldAssignment.ended_at = new Date();
        await assignmentRepo.save(oldAssignment);
      }

      const newAssignment = await assignmentRepo.save(
        assignmentRepo.create({
          incident_id,
          department_id: new_department_id,
          assigned_by: adminId,
          assignment_method: "MANUAL",
          reason,
          assigned_at: new Date(),
        }),
      );
      const oldStatus = incident.status;
      incident.status = "ASSIGNED";
      incident.resolved_at = null;
      await incidentRepo.save(incident);
      await updateRepo.save(
        updateRepo.create({
          incident_id,
          updated_by: adminId,
          old_status: oldStatus,
          new_status: "ASSIGNED",
          note: `Admin reassign: ${reason}`,
        }),
      );
      await new AuditLogService().record(
        {
          user_id: adminId,
          action: "INCIDENT_REASSIGNED",
          entity_type: "incident",
          entity_id: incident_id,
          details: {
            old_department_id: oldAssignment?.department_id,
            new_department_id,
            reason,
          },
        },
        manager,
      );
      await new NotificationService().notifyDepartment(
        incident_id,
        new_department_id,
        manager,
        newAssignment.id,
      );
      return newAssignment;
    });
  }

  async approveAiSuggestion(incidentId: string, adminId: string) {
    return AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const updateRepo = manager.getRepository(IncidentUpdate);

      const incident = await incidentRepo.findOne({
        where: { id: incidentId },
        lock: { mode: "pessimistic_write" },
      });
      if (!incident) throw { statusCode: 404, message: "Không tìm thấy sự cố" };
      if (["RESOLVED", "REJECTED", "CANCELLED"].includes(incident.status)) {
        throw {
          statusCode: 409,
          message: "Không thể phân công hồ sơ đã kết thúc",
        };
      }

      let deptId = incident.ai_suggested_department_id;
      let officerId = incident.ai_suggested_officer_id;
      let reason =
        incident.ai_suggestion_reason ||
        "Admin duyệt phân công theo đề xuất tự động của AI";

      // Nếu chưa có gợi ý trên incident (ví dụ sự cố cũ), tính ngay gợi ý
      if (!deptId || !officerId) {
        const suggestion =
          await new DepartmentAssignmentService().suggestOfficerAssignment(
            (incident.location as any).coordinates[0],
            (incident.location as any).coordinates[1],
            incident.incident_type_id,
            manager,
            incident.description,
          );
        if (!suggestion) {
          throw {
            statusCode: 400,
            message:
              "Hệ thống không tìm thấy cán bộ/đơn vị phù hợp để phân công tự động",
          };
        }
        deptId = suggestion.department_id;
        officerId = suggestion.officer_id;
        reason = suggestion.reason;
        incident.ai_suggested_department_id = deptId;
        incident.ai_suggested_officer_id = officerId;
        incident.ai_suggestion_reason = reason;
        incident.ai_suggestion_confidence = suggestion.confidence;
      }

      // Kết thúc phân công cũ nếu có
      const oldAssignment = await assignmentRepo.findOne({
        where: { incident_id: incidentId, ended_at: IsNull() },
        lock: { mode: "pessimistic_write" },
      });
      if (oldAssignment) {
        oldAssignment.ended_at = new Date();
        await assignmentRepo.save(oldAssignment);
      }

      // Tạo phân công mới với cán bộ được AI gợi ý
      const newAssignment = await assignmentRepo.save(
        assignmentRepo.create({
          incident_id: incidentId,
          department_id: deptId,
          assigned_officer_id: officerId,
          accepted_by: null,
          assigned_by: adminId,
          assignment_method: "AI_SUGGESTED",
          reason,
          assigned_at: new Date(),
          accepted_at: null,
        }),
      );

      const oldStatus = incident.status;
      incident.status = "ASSIGNED";
      incident.resolved_at = null;
      await incidentRepo.save(incident);

      await updateRepo.save(
        updateRepo.create({
          incident_id: incidentId,
          updated_by: adminId,
          old_status: oldStatus,
          new_status: "ASSIGNED",
          note: `Admin duyệt phân công đề xuất của AI: ${reason}`,
        }),
      );

      await new AuditLogService().record(
        {
          user_id: adminId,
          action: "AI_ASSIGNMENT_APPROVED",
          entity_type: "incident",
          entity_id: incidentId,
          details: { department_id: deptId, officer_id: officerId, reason },
        },
        manager,
      );

      // Thông báo cho đơn vị và người dân
      await new NotificationService().notifyDepartment(
        incidentId,
        deptId,
        manager,
        newAssignment.id,
        officerId,
      );
      await new NotificationService().notifyReporters(
        incidentId,
        "ASSIGNMENT_CREATED",
        "Sự cố đã được phân công xử lý",
        `Sự cố của bạn đã được quản trị viên duyệt phân công cho cán bộ phụ trách tiếp nhận hiện trường.`,
        manager,
      );

      return newAssignment;
    });
  }

  async assignOfficer(
    data: {
      incident_id: string;
      department_id: string;
      officer_id?: string;
      reason?: string;
    },
    adminId: string,
  ) {
    const { incident_id, department_id, officer_id, reason } = data;
    return AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const updateRepo = manager.getRepository(IncidentUpdate);

      const incident = await incidentRepo.findOne({
        where: { id: incident_id },
        lock: { mode: "pessimistic_write" },
      });
      if (!incident) throw { statusCode: 404, message: "Không tìm thấy sự cố" };
      if (["RESOLVED", "REJECTED", "CANCELLED"].includes(incident.status)) {
        throw {
          statusCode: 409,
          message: "Không thể phân công hồ sơ đã kết thúc",
        };
      }

      const oldAssignment = await assignmentRepo.findOne({
        where: { incident_id, ended_at: IsNull() },
        lock: { mode: "pessimistic_write" },
      });
      if (oldAssignment) {
        oldAssignment.ended_at = new Date();
        await assignmentRepo.save(oldAssignment);
      }

      const noteText =
        reason?.trim() ||
        (officer_id
          ? "Admin phân công cán bộ xử lý"
          : "Admin phân công đơn vị xử lý");

      const newAssignment = await assignmentRepo.save(
        assignmentRepo.create({
          incident_id,
          department_id,
          assigned_officer_id: officer_id || null,
          accepted_by: null,
          assigned_by: adminId,
          assignment_method: "MANUAL",
          reason: noteText,
          assigned_at: new Date(),
          accepted_at: null,
        }),
      );

      const oldStatus = incident.status;
      incident.status = "ASSIGNED";
      incident.resolved_at = null;
      await incidentRepo.save(incident);

      await updateRepo.save(
        updateRepo.create({
          incident_id,
          updated_by: adminId,
          old_status: oldStatus,
          new_status: "ASSIGNED",
          note: noteText,
        }),
      );

      await new AuditLogService().record(
        {
          user_id: adminId,
          action: "INCIDENT_OFFICER_ASSIGNED",
          entity_type: "incident",
          entity_id: incident_id,
          details: { department_id, officer_id, reason: noteText },
        },
        manager,
      );

      await new NotificationService().notifyDepartment(
        incident_id,
        department_id,
        manager,
        newAssignment.id,
        officer_id,
      );
      await new NotificationService().notifyReporters(
        incident_id,
        "ASSIGNMENT_CREATED",
        "Sự cố đã được phân công xử lý",
        `Sự cố của bạn đã được phân công cho đơn vị phụ trách tiếp nhận hiện trường.`,
        manager,
      );

      return newAssignment;
    });
  }
}
