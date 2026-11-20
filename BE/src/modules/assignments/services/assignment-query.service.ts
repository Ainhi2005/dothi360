import { AppDataSource } from "../../../database/data-source";

import { DepartmentAssignmentService } from "../../../algorithms/department-assignment/department-assignment.service";
import { IncidentReport } from "../../incident-reports/incident-report.entity";
import { IncidentMedia } from "../../media/media.entity";
import { AssignmentServiceDependencies } from "./assignment-dependencies";

/** Tra cứu công việc và danh sách ứng viên phân công. */
export class AssignmentQueryService {
  constructor(private readonly deps: AssignmentServiceDependencies) {}

  async getOfficerAssignment(id: string, departmentId: string, userId: string) {
    const row = await this.deps.assignmentRepo
      .createQueryBuilder("assignment")
      .innerJoin("incidents", "incident", "incident.id=assignment.incident_id")
      .leftJoin("incident_types", "type", "type.id=incident.incident_type_id")
      .leftJoin(
        "departments",
        "department",
        "department.id=assignment.department_id",
      )
      .where(
        `assignment.id=:id AND assignment.department_id=:departmentId
        AND (assignment.accepted_by=:userId OR assignment.rejected_by=:userId OR
          (assignment.ended_at IS NULL AND assignment.accepted_by IS NULL
            AND (assignment.assigned_officer_id IS NULL OR assignment.assigned_officer_id=:userId)))`,
        { id, departmentId, userId },
      )
      .select([
        "assignment.id AS id",
        "assignment.incident_id AS incident_id",
        "assignment.department_id AS department_id",
        "assignment.assigned_officer_id AS assigned_officer_id",
        "assignment.accepted_by AS accepted_by",
        "assignment.assignment_method AS assignment_method",
        "assignment.reason AS reason",
        "assignment.distance_m AS distance_m",
        "assignment.assigned_at AS assigned_at",
        "assignment.accepted_at AS accepted_at",
        "assignment.ended_at AS ended_at",
        "assignment.rejected_by AS rejected_by",
        "assignment.rejection_code AS rejection_code",
        "assignment.rejection_reason AS rejection_reason",
        "assignment.rejected_at AS rejected_at",
        `CASE
          WHEN assignment.rejected_at IS NOT NULL THEN 'REJECTED'
          WHEN assignment.ended_at IS NOT NULL AND incident.status = 'RESOLVED' THEN 'COMPLETED'
          WHEN assignment.ended_at IS NOT NULL THEN 'REASSIGNED'
          WHEN assignment.accepted_by IS NOT NULL THEN 'ACTIVE'
          ELSE 'WAITING'
        END AS assignment_state`,
        "incident.description AS description",
        "incident.status AS status",
        "incident.severity_level AS severity_level",
        "incident.priority_score AS priority_score",
        "incident.priority_level AS priority_level",
        "incident.report_count AS report_count",
        "incident.created_at AS incident_created_at",
        "ST_Y(incident.location::geometry) AS latitude",
        "ST_X(incident.location::geometry) AS longitude",
        "type.name AS incident_type_name",
        "department.name AS department_name",
        `(SELECT report.reported_address
          FROM incident_reports report
          WHERE report.incident_id = incident.id
            AND NULLIF(TRIM(report.reported_address), '') IS NOT NULL
          ORDER BY report.created_at ASC
          LIMIT 1) AS address`,
        "(SELECT u.progress_percent FROM incident_updates u WHERE u.incident_id=incident.id AND u.progress_percent IS NOT NULL ORDER BY u.created_at DESC LIMIT 1) AS progress_percent",
      ])
      .getRawOne();
    if (!row)
      throw {
        statusCode: 404,
        message: "Nhiệm vụ không tồn tại hoặc không thuộc đơn vị của bạn",
      };

    const [reportWithAi, mediaRecords] = await Promise.all([
      AppDataSource.getRepository(IncidentReport)
        .createQueryBuilder("report")
        .where(
          "report.incident_id = :incidentId AND report.ai_analysis IS NOT NULL",
          { incidentId: row.incident_id },
        )
        .orderBy("report.created_at", "DESC")
        .getOne(),
      AppDataSource.getRepository(IncidentMedia).find({
        where: { incident_id: row.incident_id },
        order: { created_at: "ASC" },
      }),
    ]);

    const latestReport =
      reportWithAi ||
      (await AppDataSource.getRepository(IncidentReport).findOne({
        where: { incident_id: row.incident_id },
        order: { created_at: "DESC" },
      }));

    return {
      ...row,
      ai_analysis:
        reportWithAi?.ai_analysis ?? latestReport?.ai_analysis ?? null,
      media: mediaRecords.map((media) => ({
        id: media.id,
        file_url: media.file_url,
      })),
      media_urls: mediaRecords.map((media) => media.file_url),
    };
  }

  async getAllAssignments(query: any = {}) {
    const page = Math.max(Number(query.page) || 1, 1),
      limit = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
    const qb = this.deps.incidentRepo
      .createQueryBuilder("incident")
      .leftJoin("incident_types", "type", "type.id = incident.incident_type_id")
      .leftJoin(
        "incident_assignments",
        "assignment",
        "assignment.incident_id = incident.id AND assignment.ended_at IS NULL",
      )
      .leftJoin(
        "incident_assignments",
        "rejected_assignment",
        `rejected_assignment.incident_id = incident.id
          AND rejected_assignment.rejected_at = (
            SELECT MAX(previous.rejected_at) FROM incident_assignments previous
            WHERE previous.incident_id = incident.id
          )`,
      )
      .leftJoin(
        "users",
        "rejecting_officer",
        "rejecting_officer.id = rejected_assignment.rejected_by",
      )
      .leftJoin(
        "departments",
        "department",
        "department.id = assignment.department_id",
      )
      .leftJoin("users", "officer", "officer.id = assignment.accepted_by")
      .leftJoin(
        "users",
        "assigned_officer",
        "assigned_officer.id = assignment.assigned_officer_id",
      )
      .leftJoin(
        "departments",
        "suggested_dept",
        "suggested_dept.id = incident.ai_suggested_department_id",
      )
      .leftJoin(
        "users",
        "suggested_officer",
        "suggested_officer.id = incident.ai_suggested_officer_id",
      )
      .select([
        "assignment.id AS id",
        "incident.id AS incident_id",
        "assignment.department_id AS department_id",
        "assignment.assignment_method AS assignment_method",
        "assignment.reason AS reason",
        "assignment.assigned_at AS assigned_at",
        "assignment.assigned_officer_id AS assigned_officer_id",
        "assignment.accepted_by AS accepted_by",
        "assignment.accepted_at AS accepted_at",
        "assignment.ended_at AS ended_at",
        "incident.description AS description",
        "incident.status AS status",
        "incident.priority_score AS priority_score",
        "incident.priority_level AS priority_level",
        "incident.created_at AS created_at",
        "incident.ai_suggested_department_id AS ai_suggested_department_id",
        "incident.ai_suggested_officer_id AS ai_suggested_officer_id",
        "incident.ai_suggestion_reason AS ai_suggestion_reason",
        "incident.ai_suggestion_confidence AS ai_suggestion_confidence",
        "suggested_dept.name AS ai_suggested_department_name",
        "suggested_officer.full_name AS ai_suggested_officer_name",
        "type.name AS incident_type_name",
        "department.name AS department_name",
        "officer.full_name AS officer_name",
        "assigned_officer.full_name AS assigned_officer_name",
        "assigned_officer.phone AS assigned_officer_phone",
        "rejected_assignment.rejection_code AS rejection_code",
        "rejected_assignment.rejection_reason AS rejection_reason",
        "rejected_assignment.rejected_at AS rejected_at",
        "rejecting_officer.full_name AS rejecting_officer_name",
      ])
      .orderBy("incident.created_at", "DESC");

    if (query.status)
      qb.andWhere("incident.status=:status", { status: query.status });
    if (query.department_id)
      qb.andWhere("assignment.department_id=:department_id", {
        department_id: query.department_id,
      });

    const total = await qb.clone().getCount();
    const data = await qb
      .offset((page - 1) * limit)
      .limit(limit)
      .getRawMany();
    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getDepartmentAssignments(
    departmentId: string,
    userId: string,
    scope: string,
  ) {
    const query = this.deps.assignmentRepo
      .createQueryBuilder("assignment")
      .innerJoin(
        "incidents",
        "incident",
        "incident.id = assignment.incident_id",
      )
      .leftJoin("incident_types", "type", "type.id = incident.incident_type_id")
      .leftJoin(
        "departments",
        "department",
        "department.id = assignment.department_id",
      )
      .where("assignment.department_id = :departmentId", { departmentId })
      .select([
        "assignment.id AS id",
        "assignment.incident_id AS incident_id",
        "assignment.department_id AS department_id",
        "assignment.assigned_officer_id AS assigned_officer_id",
        "assignment.accepted_by AS accepted_by",
        "assignment.assignment_method AS assignment_method",
        "assignment.reason AS reason",
        "assignment.distance_m AS distance_m",
        "assignment.assigned_at AS assigned_at",
        "assignment.accepted_at AS accepted_at",
        "assignment.ended_at AS ended_at",
        "assignment.rejected_by AS rejected_by",
        "assignment.rejection_code AS rejection_code",
        "assignment.rejection_reason AS rejection_reason",
        "assignment.rejected_at AS rejected_at",
        `CASE
          WHEN assignment.rejected_at IS NOT NULL THEN 'REJECTED'
          WHEN assignment.ended_at IS NOT NULL AND incident.status = 'RESOLVED' THEN 'COMPLETED'
          WHEN assignment.ended_at IS NOT NULL THEN 'REASSIGNED'
          WHEN assignment.accepted_by IS NOT NULL THEN 'ACTIVE'
          ELSE 'WAITING'
        END AS assignment_state`,
        "incident.description AS description",
        "incident.status AS status",
        "incident.severity_level AS severity_level",
        "incident.priority_score AS priority_score",
        "incident.priority_level AS priority_level",
        "incident.report_count AS report_count",
        "incident.created_at AS incident_created_at",
        `(incident.created_at + (CASE incident.priority_level WHEN 'EMERGENCY' THEN INTERVAL '1 hour' WHEN 'HIGH' THEN INTERVAL '4 hours' WHEN 'MEDIUM' THEN INTERVAL '12 hours' ELSE INTERVAL '24 hours' END)) AS sla_deadline`,
        `(SELECT MAX(u.created_at) FROM incident_updates u WHERE u.incident_id=incident.id) AS last_progress_at`,
        `(SELECT COUNT(*)::int FROM incident_updates u WHERE u.incident_id=incident.id AND u.new_status='PENDING_VERIFICATION') AS verification_attempts`,
        `EXISTS(SELECT 1 FROM incident_updates u WHERE u.incident_id=incident.id AND u.old_status='PENDING_VERIFICATION' AND u.new_status='IN_PROGRESS' AND u.created_at=(SELECT MAX(u2.created_at) FROM incident_updates u2 WHERE u2.incident_id=incident.id)) AS rework_required`,
        `(SELECT u.progress_percent FROM incident_updates u WHERE u.incident_id=incident.id AND u.progress_percent IS NOT NULL ORDER BY u.created_at DESC LIMIT 1) AS progress_percent`,
        `(SELECT m.file_url FROM incident_media m
          WHERE m.incident_id = incident.id AND m.media_type = 'IMAGE'
          ORDER BY m.created_at ASC LIMIT 1) AS cover_url`,
        "ST_Y(incident.location::geometry) AS latitude",
        "ST_X(incident.location::geometry) AS longitude",
        "type.name AS incident_type_name",
        "department.name AS department_name",
        `(SELECT report.reported_address
          FROM incident_reports report
          WHERE report.incident_id = incident.id
            AND NULLIF(TRIM(report.reported_address), '') IS NOT NULL
          ORDER BY report.created_at ASC
          LIMIT 1) AS address`,
      ]);

    if (scope === "queue") {
      query
        .andWhere("assignment.ended_at IS NULL")
        .andWhere("assignment.accepted_by IS NULL")
        .andWhere("incident.status = 'ASSIGNED'")
        .andWhere(
          "(assignment.assigned_officer_id IS NULL OR assignment.assigned_officer_id = :userId)",
          { userId },
        );
    } else if (scope === "mine") {
      query
        .andWhere("assignment.ended_at IS NULL")
        .andWhere("assignment.accepted_by = :userId", { userId })
        .andWhere(
          "incident.status IN ('ACCEPTED', 'IN_PROGRESS', 'PENDING_VERIFICATION')",
        );
    } else if (scope === "history") {
      query
        .andWhere("assignment.ended_at IS NOT NULL")
        .andWhere(
          "(assignment.accepted_by = :userId OR assignment.rejected_by = :userId)",
          { userId },
        );
    } else {
      query
        .andWhere("assignment.ended_at IS NULL")
        .andWhere(
          "incident.status NOT IN ('RESOLVED', 'REJECTED', 'CANCELLED', 'PENDING_ASSIGNMENT')",
        )
        .andWhere(
          `(assignment.accepted_by = :userId OR
          (assignment.accepted_by IS NULL AND (assignment.assigned_officer_id IS NULL OR assignment.assigned_officer_id = :userId)))`,
          { userId },
        );
    }

    return query
      .orderBy("incident.priority_score", "DESC", "NULLS LAST")
      .addOrderBy("assignment.assigned_at", "ASC")
      .getRawMany();
  }

  async getCandidates(incidentId: string) {
    const incident = await this.deps.incidentRepo.findOne({
      where: { id: incidentId },
      relations: { incident_type: true },
    });
    if (!incident) throw { statusCode: 404, message: "Không tìm thấy sự cố" };

    const coords = (incident.location as any).coordinates;
    const suggestion =
      await new DepartmentAssignmentService().suggestOfficerAssignment(
        coords[0],
        coords[1],
        incident.incident_type_id,
        AppDataSource.manager,
        incident.description,
      );

    const departments = await AppDataSource.query(
      `
      SELECT d.id, d.code, d.name, d.address, d.phone,
        COALESCE(ST_Distance(d.location, ST_SetSRID(ST_Point($1, $2), 4326)::geography), 99999)::int AS distance_m
      FROM departments d
      WHERE d.is_active = TRUE
      ORDER BY distance_m ASC
    `,
      [coords[0], coords[1]],
    );

    const officers = await AppDataSource.query(`
      SELECT u.id, u.full_name, u.email, u.phone, u.department_id, d.name AS department_name,
        COALESCE((
          SELECT COUNT(*)::int
          FROM incident_assignments a
          JOIN incidents i ON i.id = a.incident_id
          WHERE a.accepted_by = u.id AND a.ended_at IS NULL AND i.status NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED')
        ), 0)::int AS active_workload
      FROM users u
      JOIN departments d ON d.id = u.department_id
      WHERE u.role = 'OFFICER' AND u.is_active = TRUE AND d.is_active = TRUE
      ORDER BY d.name, active_workload ASC, u.full_name ASC
    `);

    return {
      incident: {
        id: incident.id,
        description: incident.description,
        incident_type_name: incident.incident_type?.name,
        status: incident.status,
        ai_suggested_department_id: incident.ai_suggested_department_id,
        ai_suggested_officer_id: incident.ai_suggested_officer_id,
        ai_suggestion_reason: incident.ai_suggestion_reason,
        ai_suggestion_confidence: incident.ai_suggestion_confidence,
      },
      suggestion,
      departments,
      officers,
    };
  }
}
