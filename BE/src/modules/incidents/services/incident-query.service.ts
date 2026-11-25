import { AppDataSource } from "../../../database/data-source";

import { IncidentMedia } from "../../media/media.entity";

import { Department } from "../../departments/department.entity";

import { DepartmentAssignmentService } from "../../../algorithms/department-assignment/department-assignment.service";

import {
  canViewInternalIncidentData,
  IncidentViewer,
} from "../incident.policy";

import { IncidentServiceDependencies } from "./incident-dependencies";

/** Tra cứu hồ sơ, lịch sử và bản đồ; lọc dữ liệu theo quyền xem. */
export class IncidentQueryService {
  constructor(private readonly deps: IncidentServiceDependencies) {}

  async findNearby(latitude: number, longitude: number, radiusM = 10000) {
    if (
      !Number.isFinite(latitude) || Math.abs(latitude) > 90 ||
      !Number.isFinite(longitude) || Math.abs(longitude) > 180 ||
      !Number.isFinite(radiusM) || radiusM < 200 || radiusM > 100000
    ) {
      throw { statusCode: 400, message: "Tọa độ hoặc bán kính tìm kiếm không hợp lệ" };
    }
    const point = "ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography";
    const result = await this.deps.incidentRepo.createQueryBuilder("incident")
      .leftJoinAndSelect("incident.incident_type", "type")
      .addSelect(`ST_Distance(incident.location, ${point})`, "distance_m")
      .addSelect(`(SELECT m.file_url FROM incident_media m
        WHERE m.incident_id = incident.id AND m.media_type = 'IMAGE'
        ORDER BY m.created_at ASC, m.id ASC LIMIT 1)`, "cover_url")
      .addSelect(`(SELECT r.reported_address FROM incident_reports r
        WHERE r.incident_id = incident.id AND NULLIF(TRIM(r.reported_address), '') IS NOT NULL
        ORDER BY r.created_at ASC, r.id ASC LIMIT 1)`, "reported_address")
      .where("incident.status NOT IN (:...closed)", {
        closed: ["RESOLVED", "REJECTED", "CANCELLED"],
      })
      .andWhere(`ST_DWithin(incident.location, ${point}, :radiusM)`)
      .setParameters({ latitude, longitude, radiusM })
      .orderBy("distance_m", "ASC")
      .addOrderBy("incident.created_at", "DESC")
      .addOrderBy("incident.id", "ASC")
      .limit(8)
      .getRawAndEntities();
    const details = new Map(result.raw.map(row => [row.incident_id, row]));
    return result.entities.map(incident => {
      const row = details.get(incident.id)!;
      return {
        ...incident,
        distance_m: Number(row.distance_m),
        cover_url: row.cover_url ?? null,
        address: row.reported_address ?? null,
      };
    });
  }

  async findAll(query: any) {
    const page = Math.max(Number(query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
    const {
      status,
      incident_type_id,
      priority,
      q,
      manual_review,
      sort_by,
      sort_order,
    } = query;
    const skip = (page - 1) * limit;

    const qb = this.deps.incidentRepo
      .createQueryBuilder("incident")
      .leftJoinAndSelect("incident.incident_type", "type");

    const orderDirection = sort_order?.toUpperCase() === "ASC" ? "ASC" : "DESC";

    if (sort_by === "priority") {
      qb.orderBy("incident.priority_score", orderDirection).addOrderBy(
        "incident.created_at",
        "DESC",
      );
    } else if (sort_by === "report_count") {
      qb.orderBy("incident.report_count", orderDirection).addOrderBy(
        "incident.created_at",
        "DESC",
      );
    } else if (sort_by === "status") {
      qb.orderBy("incident.status", orderDirection).addOrderBy(
        "incident.created_at",
        "DESC",
      );
    } else {
      // Mặc định: Sự cố mới nhất lên đầu (created_at DESC)
      qb.orderBy("incident.created_at", orderDirection).addOrderBy(
        "incident.priority_score",
        "DESC",
      );
    }

    qb.skip(skip).take(limit);

    if (status) qb.andWhere("incident.status = :status", { status });
    if (incident_type_id)
      qb.andWhere("incident.incident_type_id = :incident_type_id", {
        incident_type_id,
      });
    if (priority)
      qb.andWhere("incident.priority_level = :priority", { priority });
    if (q)
      qb.andWhere("(incident.description ILIKE :q OR type.name ILIKE :q)", {
        q: `%${q}%`,
      });
    if (manual_review === "true")
      qb.andWhere(
        `EXISTS (SELECT 1 FROM incident_reports report WHERE report.incident_id=incident.id AND report.requires_manual_review=TRUE)`,
      );

    const [data, total] = await qb.getManyAndCount();
    const ids = data.map((incident) => incident.id);
    const coverRows = ids.length
      ? await this.deps.mediaRepo
          .createQueryBuilder("media")
          .distinctOn(["media.incident_id"])
          .select("media.incident_id", "incident_id")
          .addSelect("media.file_url", "file_url")
          .where("media.incident_id IN (:...ids)", { ids })
          .andWhere("media.media_type = 'IMAGE'")
          .orderBy("media.incident_id")
          .addOrderBy("media.created_at", "ASC")
          .getRawMany()
      : [];
    const covers = new Map(
      coverRows.map((row) => [row.incident_id, row.file_url]),
    );

    const deptRows = ids.length
      ? await this.deps.assignmentRepo
          .createQueryBuilder("assignment")
          .innerJoin(Department, "dept", "dept.id = assignment.department_id")
          .where("assignment.incident_id IN (:...ids)", { ids })
          .orderBy(
            "CASE WHEN assignment.ended_at IS NULL THEN 0 ELSE 1 END",
            "ASC",
          )
          .addOrderBy("assignment.assigned_at", "DESC")
          .select("assignment.incident_id", "incident_id")
          .addSelect("dept.name", "department_name")
          .getRawMany()
      : [];
    const depts = new Map(
      deptRows.map((r: any) => [r.incident_id, r.department_name]),
    );

    return {
      data: data.map((incident) => ({
        ...incident,
        cover_url: covers.get(incident.id) ?? null,
        assigned_department: depts.get(incident.id)
          ? { name: depts.get(incident.id) }
          : null,
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findOne(id: string) {
    const incident = await this.deps.incidentRepo.findOne({
      where: { id },
      relations: { incident_type: true },
    });
    if (!incident) throw { statusCode: 404, message: "Không tìm thấy sự cố" };

    const [allMedia, rawUpdates, assignment, latestReport, reportWithAi] =
      await Promise.all([
        this.deps.mediaRepo.find({
          where: { incident_id: id },
          order: { created_at: "ASC" },
        }),
        this.deps.updateRepo.find({
          where: { incident_id: id },
          order: { created_at: "ASC" },
        }),
        this.deps.assignmentRepo
          .createQueryBuilder("assignment")
          .leftJoin(
            Department,
            "department",
            "department.id = assignment.department_id",
          )
          .leftJoin("users", "officer", "officer.id = assignment.accepted_by")
          .leftJoin(
            "users",
            "assigned_officer",
            "assigned_officer.id = assignment.assigned_officer_id",
          )
          .where("assignment.incident_id = :id", { id })
          .orderBy(
            "CASE WHEN assignment.ended_at IS NULL THEN 0 ELSE 1 END",
            "ASC",
          )
          .addOrderBy("assignment.assigned_at", "DESC")
          .select([
            "assignment.id AS id",
            "assignment.department_id AS department_id",
            "assignment.assigned_officer_id AS assigned_officer_id",
            "assignment.accepted_by AS accepted_by",
            "assignment.assignment_method AS assignment_method",
            "assignment.reason AS reason",
            "assignment.assigned_at AS assigned_at",
            "assignment.accepted_at AS accepted_at",
            "department.name AS department_name",
            "officer.full_name AS officer_name",
            "officer.phone AS officer_phone",
            "assigned_officer.full_name AS assigned_officer_name",
            "assigned_officer.phone AS assigned_officer_phone",
          ])
          .getRawOne(),
        this.deps.reportRepo.findOne({
          where: { incident_id: id },
          order: { created_at: "DESC" },
        }),
        this.deps.reportRepo
          .createQueryBuilder("report")
          .where(
            "report.incident_id = :id AND report.ai_analysis IS NOT NULL",
            { id },
          )
          .orderBy("report.created_at", "DESC")
          .getOne(),
      ]);

    const updates = rawUpdates.map((u) => ({
      ...u,
      media: allMedia
        .filter((m) => m.update_id === u.id)
        .map((m) => ({
          id: m.id,
          file_url: m.file_url,
          media_type: m.media_type,
        })),
      media_urls: allMedia
        .filter((m) => m.update_id === u.id)
        .map((m) => m.file_url),
    }));

    const reportMedia = allMedia.filter((m) => !m.update_id);
    const officerMedia = allMedia.filter((m) => m.update_id);
    const targetReport = reportWithAi ?? latestReport;

    let aiSuggestion: any = null;
    if (
      incident.ai_suggested_department_id ||
      incident.ai_suggested_officer_id
    ) {
      const [deptRows, officerRows] = await Promise.all([
        incident.ai_suggested_department_id
          ? AppDataSource.query(
              "SELECT id, name, phone FROM departments WHERE id = $1",
              [incident.ai_suggested_department_id],
            )
          : [],
        incident.ai_suggested_officer_id
          ? AppDataSource.query(
              `
          SELECT u.id, u.full_name, u.phone,
            COALESCE((
              SELECT COUNT(*)::int
              FROM incident_assignments a
              JOIN incidents i ON i.id = a.incident_id
              WHERE a.accepted_by = u.id AND a.ended_at IS NULL AND i.status NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED')
            ), 0)::int AS active_workload
          FROM users u WHERE u.id = $1
        `,
              [incident.ai_suggested_officer_id],
            )
          : [],
      ]);
      aiSuggestion = {
        department_id: incident.ai_suggested_department_id,
        department_name: deptRows[0]?.name ?? null,
        officer_id: incident.ai_suggested_officer_id,
        officer_name: officerRows[0]?.full_name ?? null,
        officer_phone: officerRows[0]?.phone ?? null,
        active_workload: officerRows[0]?.active_workload ?? 0,
        reason: incident.ai_suggestion_reason,
        confidence: incident.ai_suggestion_confidence
          ? Number(incident.ai_suggestion_confidence)
          : 0.95,
      };
    } else if (incident.status === "PENDING_ASSIGNMENT") {
      const coords = (incident.location as any).coordinates;
      aiSuggestion =
        await new DepartmentAssignmentService().suggestOfficerAssignment(
          coords[0],
          coords[1],
          incident.incident_type_id,
          AppDataSource.manager,
          incident.description,
        );
    }

    return {
      ...incident,
      media: allMedia,
      report_media: reportMedia,
      officer_media: officerMedia,
      updates,
      assignment,
      ai_suggestion: aiSuggestion,
      ai_analysis: targetReport?.ai_analysis ?? null,
      duplicate_evidence: targetReport?.duplicate_evidence ?? null,
    };
  }

  async findOneForViewer(id: string, viewer?: IncidentViewer) {
    const incident = await this.findOne(id);
    const [reports, assignments] = await Promise.all([
      this.deps.reportRepo.find({
        where: { incident_id: id },
        select: { reporter_id: true },
      }),
      this.deps.assignmentRepo.find({
        where: { incident_id: id },
        select: { department_id: true },
      }),
    ]);
    const isMine = Boolean(
      viewer?.id && reports.some((report) => report.reporter_id === viewer.id),
    );
    const canViewInternal = canViewInternalIncidentData(
      viewer,
      reports.map((report) => report.reporter_id),
      assignments.map((assignment) => assignment.department_id),
    );
    if (viewer?.role === "OFFICER" && !canViewInternal) {
      throw { statusCode: 403, message: "Sự cố không thuộc đơn vị của bạn" };
    }
    const resolvedUpdate = incident.updates?.find(
      (update: any) => update.new_status === "RESOLVED",
    );
    const verificationNote = resolvedUpdate?.note ?? null;

    if (canViewInternal && viewer?.role !== "CITIZEN")
      return {
        ...incident,
        verification_note: verificationNote,
        is_mine: isMine,
      };
    if (canViewInternal && viewer?.role === "CITIZEN") {
      const updates = incident.updates.filter(
        (update: any) => update.visibility !== "INTERNAL",
      );
      const updateIds = new Set(updates.map((update: any) => update.id));
      return {
        ...incident,
        verification_note: verificationNote,
        updates,
        officer_media: incident.officer_media.filter(
          (media: any) => !media.update_id || updateIds.has(media.update_id),
        ),
        is_mine: isMine,
      };
    }
    const { assignment: _assignment, ...publicIncident } = incident;
    const publicUpdates = publicIncident.updates.filter(
      (update: any) => update.visibility !== "INTERNAL",
    );
    const publicUpdateIds = new Set(
      publicUpdates.map((update: any) => update.id),
    );
    const publicAssignment = _assignment
      ? {
          id: _assignment.id,
          department_id: _assignment.department_id,
          department_name: _assignment.department_name,
          assigned_at: _assignment.assigned_at,
          accepted_at: _assignment.accepted_at,
        }
      : null;
    return {
      ...publicIncident,
      verification_note: verificationNote,
      assignment: publicAssignment,
      updates: publicUpdates,
      officer_media: publicIncident.officer_media.filter(
        (media: any) =>
          !media.update_id || publicUpdateIds.has(media.update_id),
      ),
      is_mine: isMine,
    };
  }

  async getMyReports(userId: string) {
    const reports = await this.deps.reportRepo.find({
      where: { reporter_id: userId },
      relations: { incident: { incident_type: true } },
      order: { created_at: "DESC" },
    });

    if (reports.length === 0) return [];

    const reportIds = reports.map((report) => report.id);
    const media = await this.deps.mediaRepo
      .createQueryBuilder("media")
      .where("media.report_id IN (:...reportIds)", { reportIds })
      .orderBy("media.created_at", "ASC")
      .getMany();

    const mediaByReport = new Map<string, IncidentMedia[]>();
    for (const item of media) {
      if (!item.report_id) continue;
      const items = mediaByReport.get(item.report_id) ?? [];
      items.push(item);
      mediaByReport.set(item.report_id, items);
    }

    return reports.map((report) => ({
      ...report,
      media: mediaByReport.get(report.id) ?? [],
    }));
  }

  async getByBoundingBox(
    minLng: number,
    minLat: number,
    maxLng: number,
    maxLat: number,
  ) {
    return this.deps.incidentRepo
      .createQueryBuilder("incident")
      .leftJoinAndSelect("incident.incident_type", "type")
      .where(
        `ST_MakeEnvelope(:minLng, :minLat, :maxLng, :maxLat, 4326) ~ incident.location::geometry`,
        {
          minLng,
          minLat,
          maxLng,
          maxLat,
        },
      )
      .getMany();
  }
}
