import { AppDataSource } from "../../../database/data-source";
import { Incident } from "../incident.entity";
import { IncidentReport } from "../../incident-reports/incident-report.entity";
import { IncidentMedia } from "../../media/media.entity";
import { IncidentType } from "../../incident-types/incident-type.entity";
import { IncidentAssignment } from "../../assignments/assignment.entity";

import { IncidentServiceDependencies } from "./incident-dependencies";

/** Duyệt phản ánh cần xác minh thủ công. */
export class IncidentReviewService {
  constructor(private readonly deps: IncidentServiceDependencies) {}

  async listManualReview(query: { page?: unknown; limit?: unknown }) {
    const page = Math.max(Number(query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
    const qb = this.deps.reportRepo
      .createQueryBuilder("report")
      .innerJoinAndSelect("report.incident", "incident")
      .leftJoinAndSelect("incident.incident_type", "type")
      .leftJoinAndMapMany(
        "report.media",
        IncidentMedia,
        "media",
        "media.report_id=report.id",
      )
      .where("report.requires_manual_review=TRUE")
      .orderBy("report.created_at", "ASC")
      .skip((page - 1) * limit)
      .take(limit);
    const [data, total] = await qb.getManyAndCount();
    return {
      data,
      meta: { page, limit, total, total_pages: Math.ceil(total / limit) },
    };
  }

  async reviewReport(
    reportId: string,
    reviewerId: string,
    data: {
      decision: "APPROVE" | "REJECT";
      incident_type_id?: string;
      note: string;
    },
  ) {
    return AppDataSource.transaction(async (manager) => {
      const reportRepo = manager.getRepository(IncidentReport);
      const incidentRepo = manager.getRepository(Incident);
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const report = await reportRepo.findOne({
        where: { id: reportId },
        lock: { mode: "pessimistic_write" },
      });
      if (!report)
        throw {
          statusCode: 404,
          message: "Không tìm thấy phản ánh cần kiểm duyệt",
        };
      if (!report.requires_manual_review)
        throw { statusCode: 409, message: "Phản ánh này đã được kiểm duyệt" };
      const incident = await incidentRepo.findOne({
        where: { id: report.incident_id },
        lock: { mode: "pessimistic_write" },
      });
      if (!incident) throw { statusCode: 404, message: "Không tìm thấy sự cố" };

      report.requires_manual_review = false;
      report.ai_analysis = {
        ...(report.ai_analysis ?? {}),
        review: {
          decision: data.decision,
          note: data.note,
          reviewer_id: reviewerId,
          reviewed_at: new Date().toISOString(),
        },
      };
      await reportRepo.save(report);
      await manager.query(
        `INSERT INTO ai_feedbacks(report_id,actor_id,source,ai_incident_type,confirmed_incident_type_id,ai_severity,confirmed_severity,decision,note) VALUES($1,$2,'ADMIN_REVIEW',$3,$4,$5,$6,$7,$8)`,
        [
          report.id,
          reviewerId,
          (report.ai_analysis as any)?.suggested_incident_type ?? null,
          data.incident_type_id ?? null,
          (report.ai_analysis as any)?.suggested_severity ?? null,
          report.reported_severity ?? null,
          data.decision,
          data.note,
        ],
      );

      if (data.decision === "REJECT") {
        const otherReports = await reportRepo.count({
          where: { incident_id: incident.id, requires_manual_review: false },
        });
        if (otherReports <= 1 && incident.status === "PENDING_ASSIGNMENT")
          incident.status = "REJECTED";
        await incidentRepo.save(incident);
        await this.deps.notificationService.create(
          {
            user_id: report.reporter_id,
            incident_id: incident.id,
            type: "REPORT_REJECTED",
            title: "Phản ánh chưa được chấp nhận",
            message: data.note,
            data: { incident_id: incident.id },
          },
          manager,
        );
      } else {
        const type = await manager
          .getRepository(IncidentType)
          .findOne({ where: { id: data.incident_type_id!, is_active: true } });
        if (!type)
          throw {
            statusCode: 404,
            message: "Loại sự cố không tồn tại hoặc đã ngừng sử dụng",
          };
        incident.incident_type_id = type.id;
        const coordinates = incident.location.coordinates;
        const assigned =
          await this.deps.assignmentService.findAssignedDepartment(
            coordinates[0],
            coordinates[1],
            type.id,
            manager,
          );
        if (assigned && incident.status === "PENDING_ASSIGNMENT") {
          await assignmentRepo.save(
            assignmentRepo.create({
              incident_id: incident.id,
              department_id: assigned.id,
              assignment_method: assigned.assignment_method,
              workload_at_assignment: assigned.workload,
              distance_m: assigned.distance_m,
            }),
          );
          incident.status = "ASSIGNED";
          await this.deps.notificationService.notifyDepartment(
            incident.id,
            assigned.id,
            manager,
          );
        }
        await incidentRepo.save(incident);
        if (incident.status === "PENDING_ASSIGNMENT") {
          await this.deps.notificationService.notifyAdmins(
            {
              eventKey: `review-approved:${report.id}`,
              type: "INCIDENT_PENDING_ASSIGNMENT",
              incidentId: incident.id,
              title: "Phản ánh đã duyệt cần phân công",
              message:
                "Chưa xác định được đơn vị phù hợp. Vui lòng phân công thủ công.",
              actionPath: `/incidents/${incident.id}`,
              actionLabel: "Mở và phân công",
            },
            manager,
          );
        }
        await this.deps.notificationService.create(
          {
            user_id: report.reporter_id,
            incident_id: incident.id,
            type: "REPORT_APPROVED",
            title: "Phản ánh đã được xác minh",
            message: "Phản ánh đã được chuyển sang quy trình xử lý.",
            data: { incident_id: incident.id },
          },
          manager,
        );
      }
      await this.deps.auditLogService.record(
        {
          user_id: reviewerId,
          action: `REPORT_REVIEW_${data.decision}`,
          entity_type: "incident_report",
          entity_id: report.id,
          details: {
            incident_id: incident.id,
            note: data.note,
            incident_type_id: data.incident_type_id,
          },
        },
        manager,
      );
      return {
        report_id: report.id,
        incident_id: incident.id,
        decision: data.decision,
        incident_status: incident.status,
      };
    });
  }
}
