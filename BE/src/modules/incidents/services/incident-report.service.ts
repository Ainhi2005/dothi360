import { normalizeMedia, type UploadedMedia } from "../incident-media";
import { ILike } from "typeorm";
import { AppDataSource } from "../../../database/data-source";
import { Incident } from "../incident.entity";
import { IncidentReport } from "../../incident-reports/incident-report.entity";
import { IncidentMedia } from "../../media/media.entity";
import { IncidentType } from "../../incident-types/incident-type.entity";
import { IncidentAssignment } from "../../assignments/assignment.entity";

import { DepartmentAssignmentService } from "../../../algorithms/department-assignment/department-assignment.service";

import { IncidentServiceDependencies } from "./incident-dependencies";

/** Tạo, gộp và xác nhận cùng gặp sự cố; giữ nguyên transaction. */
export class IncidentReportService {
  constructor(private readonly deps: IncidentServiceDependencies) {}

  async createReport(reporterId: string, data: any) {
    let {
      incident_type_id,
      description,
      longitude,
      latitude,
      reported_address,
      location_source,
      reported_severity,
      media_urls,
      ai_confirmation,
      ai_analysis,
    } = data;
    let aiAnalysis: any = ai_analysis ?? null;

    // Nếu client ĐÃ phân tích ở bước trước và người dùng đã duyệt/xác nhận thì dùng luôn kết quả đó,
    // KHÔNG gọi lại AI để tránh tốn tài nguyên và ghi đè nội dung người dùng đã duyệt.
    if (!aiAnalysis && media_urls && media_urls.length > 0) {
      console.log("Chưa có kết quả AI từ client, đang phân tích ảnh mới...");
      const imageUrls = (media_urls as Array<string | UploadedMedia>)
        .map((item) => (typeof item === "string" ? item : item.url))
        .filter(Boolean);
      aiAnalysis = await this.deps.aiService.analyzeIncidentImages(
        imageUrls,
        description,
      );
    }

    if (aiAnalysis) {
      aiAnalysis = {
        ...aiAnalysis,
        original_reason:
          ai_confirmation.suggested_summary ??
          aiAnalysis.original_reason ??
          aiAnalysis.reason,
        reason: ai_confirmation.confirmed_summary,
        user_edited_reason: ai_confirmation.summary_edited === true,
      };
      // 2. Tự động điền mức độ nếu user chưa chọn
      if (!reported_severity && aiAnalysis.suggested_severity) {
        reported_severity = aiAnalysis.suggested_severity;
      }

      // 3. Tự động tìm Loại sự cố nếu user chưa chọn (User trải nghiệm 1-click)
      if (!incident_type_id && aiAnalysis.suggested_incident_type) {
        const foundType = await this.deps.typeRepo.findOne({
          where: { name: ILike(`%${aiAnalysis.suggested_incident_type}%`) },
        });
        if (foundType) {
          incident_type_id = foundType.id;
        }
      }
      if (!incident_type_id && aiAnalysis.requires_manual_review) {
        const fallbackType = await this.deps.typeRepo.findOne({
          where: { name: ILike("%Khác%"), is_active: true },
        });
        incident_type_id = fallbackType?.id;
      }

      if (ai_confirmation) {
        aiAnalysis = {
          ...aiAnalysis,
          citizen_confirmation: {
            accepted: ai_confirmation.accepted,
            displayed_suggestion: {
              incident_type: ai_confirmation.suggested_incident_type ?? null,
              severity: ai_confirmation.suggested_severity ?? null,
            },
            confirmed_incident_type_id:
              ai_confirmation.confirmed_incident_type_id,
            confirmed_severity: ai_confirmation.confirmed_severity,
            confirmed_at: ai_confirmation.confirmed_at,
            recorded_at: new Date().toISOString(),
          },
        };
      }
    }

    if (!incident_type_id) {
      throw {
        statusCode: 400,
        message:
          "Thiếu ID loại sự cố. Vui lòng chọn thủ công nếu AI không nhận ra.",
      };
    }

    return AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const reportRepo = manager.getRepository(IncidentReport);
      const mediaRepo = manager.getRepository(IncidentMedia);
      const typeRepo = manager.getRepository(IncidentType);
      const assignmentRepo = manager.getRepository(IncidentAssignment);

      // Khóa theo loại + ô địa lý khoảng 100 m để serialize các báo cáo có khả năng trùng.
      const lockKey = `${incident_type_id}:${longitude.toFixed(3)}:${latitude.toFixed(3)}`;
      await manager.query("SELECT pg_advisory_xact_lock(hashtext($1))", [
        lockKey,
      ]);

      // 1. Kiểm tra Loại sự cố
      const incidentType = await typeRepo.findOne({
        where: { id: incident_type_id },
      });
      if (!incidentType)
        throw { statusCode: 404, message: "Loại sự cố không tồn tại" };

      // 2. Thuật toán: Phát hiện trùng lặp
      const duplicateIncident = await this.deps.duplicateService.findDuplicate(
        incident_type_id,
        longitude,
        latitude,
        manager,
        description,
        aiAnalysis,
      );

      let incidentId: string;
      let isNewIncident = false;
      let mainIncident: Incident;

      if (duplicateIncident) {
        const existingReport = await reportRepo.findOne({
          where: { incident_id: duplicateIncident.id, reporter_id: reporterId },
        });
        if (existingReport) {
          return {
            message: "Bạn đã báo cáo sự cố này rồi. Cảm ơn bạn!",
            incident: duplicateIncident,
            report: existingReport,
            assignedDepartment: null,
            media_attached: false,
          };
        }
        // Đã có sự cố -> Cập nhật sự cố cũ
        incidentId = duplicateIncident.id;
        mainIncident = duplicateIncident;
        mainIncident.report_count += 1; // Tăng số lượng báo cáo

        // Thuật toán: Tính lại điểm ưu tiên
        const scoreData = await this.deps.scoringService.calculateConfigured(
          incidentType.type_priority_level,
          reported_severity || incidentType.default_severity,
          mainIncident.report_count,
          mainIncident.created_at,
          manager,
        );
        mainIncident.priority_score = scoreData.score;
        mainIncident.priority_level = scoreData.level;

        await incidentRepo.save(mainIncident);
      } else {
        // Không trùng -> Tạo sự cố mới
        isNewIncident = true;
        const scoreData = await this.deps.scoringService.calculateConfigured(
          incidentType.type_priority_level,
          reported_severity || incidentType.default_severity,
          1,
          new Date(),
          manager,
        );

        const newIncident = incidentRepo.create({
          incident_type_id,
          description,
          location: { type: "Point", coordinates: [longitude, latitude] },
          severity_level: reported_severity || incidentType.default_severity,
          status: "PENDING_ASSIGNMENT",
          priority_score: scoreData.score,
          priority_level: scoreData.level,
          report_count: 1,
        });

        mainIncident = await incidentRepo.save(newIncident);
        incidentId = mainIncident.id;
      }

      // 3. Tạo record IncidentReport (Dành riêng cho User này)
      const newReport = reportRepo.create({
        incident_id: incidentId,
        reporter_id: reporterId,
        description,
        reported_location: {
          type: "Point",
          coordinates: [longitude, latitude],
        },
        reported_address: reported_address ?? null,
        location_source: location_source ?? "GPS",
        reported_severity,
        ai_analysis: aiAnalysis,
        requires_manual_review: aiAnalysis?.requires_manual_review === true,
        duplicate_score: duplicateIncident
          ? ((duplicateIncident as any).duplicateEvidence?.score ?? null)
          : null,
        duplicate_distance_m: duplicateIncident
          ? ((duplicateIncident as any).duplicateEvidence?.distance_m ?? null)
          : null,
        duplicate_time_minutes: duplicateIncident
          ? ((duplicateIncident as any).duplicateEvidence?.time_minutes ?? null)
          : null,
        duplicate_evidence: duplicateIncident
          ? ((duplicateIncident as any).duplicateEvidence ?? null)
          : null,
      });
      const savedReport = await reportRepo.save(newReport);
      await manager.query(
        `INSERT INTO ai_feedbacks(report_id,actor_id,source,ai_incident_type,confirmed_incident_type_id,ai_severity,confirmed_severity,decision,note) VALUES($1,$2,'CITIZEN_CONFIRMATION',$3,$4,$5,$6,$7,$8)`,
        [
          savedReport.id,
          reporterId,
          aiAnalysis?.suggested_incident_type ?? null,
          incident_type_id,
          aiAnalysis?.suggested_severity ?? null,
          reported_severity ?? null,
          aiAnalysis?.suggested_incident_type ===
            ai_confirmation.suggested_incident_type &&
          aiAnalysis?.suggested_severity ===
            ai_confirmation.confirmed_severity &&
          !ai_confirmation.summary_edited
            ? "CONFIRMED"
            : "CORRECTED",
          ai_confirmation.summary_edited
            ? "Người dân đã chỉnh tóm tắt AI trước khi xác nhận"
            : "Người dân giữ nguyên tóm tắt AI và xác nhận trước khi gửi",
        ],
      );
      await this.deps.notificationService.create(
        {
          user_id: reporterId,
          incident_id: incidentId,
          type: isNewIncident ? "REPORT_RECEIVED" : "REPORT_MERGED",
          title: "Đã ghi nhận phản ánh",
          message: isNewIncident
            ? "Phản ánh của bạn đã được tiếp nhận."
            : "Phản ánh đã được gộp với sự cố đang xử lý.",
          data: { incident_id: incidentId },
        },
        manager,
      );

      if (savedReport.requires_manual_review) {
        await this.deps.notificationService.notifyAdmins(
          {
            eventKey: `manual-review:${savedReport.id}`,
            type: "REPORT_PENDING_REVIEW",
            incidentId,
            title: "Phản ánh cần kiểm duyệt",
            message: `Có phản ánh cần kiểm tra ảnh, loại và mức độ: ${description.slice(0, 160)}`,
            actionPath: "/manual-review",
            actionLabel: "Mở kiểm duyệt",
            data: { report_id: savedReport.id },
          },
          manager,
        );
      }

      // 4. Lưu Media
      if (media_urls && media_urls.length > 0) {
        const mediaRecords = media_urls.map((raw: string | UploadedMedia) => {
          const media = normalizeMedia(raw);
          return mediaRepo.create({
            incident_id: incidentId,
            report_id: savedReport.id,
            uploaded_by: reporterId,
            media_type: media.type.startsWith("video/") ? "VIDEO" : "IMAGE",
            file_url: media.url,
            storage_key: media.storage_key,
            mime_type: media.type,
            file_size: media.size,
          });
        });
        await mediaRepo.save(mediaRecords);
      }

      // Tạo tối đa một cảnh báo cho mỗi user + sự cố. Hàm notification
      // tự chống trùng nên vẫn gọi khi phản ánh được gộp vào incident đã có.
      await this.deps.notificationService.notifyInterestedAreas(
        incidentId,
        reporterId,
        manager,
      );

      // 5. Thuật toán: AI Gợi ý phân công cán bộ & đơn vị chuyên trách
      if (isNewIncident) {
        const officerSuggestion =
          await new DepartmentAssignmentService().suggestOfficerAssignment(
            longitude,
            latitude,
            incident_type_id,
            manager,
            description,
          );
        if (officerSuggestion) {
          mainIncident.ai_suggested_department_id =
            officerSuggestion.department_id;
          mainIncident.ai_suggested_officer_id = officerSuggestion.officer_id;
          mainIncident.ai_suggestion_reason = officerSuggestion.reason;
          mainIncident.ai_suggestion_confidence =
            officerSuggestion.confidence as any;
          await incidentRepo.save(mainIncident);
        }
        const incidentType = await manager.getRepository(IncidentType).findOne({
          where: { id: incident_type_id },
        });
        if (!savedReport.requires_manual_review)
          await this.deps.notificationService.notifyAdminsPendingAssignment(
            incidentId,
            incidentType?.name ?? "Sự cố đô thị",
            description,
            reported_address ?? null,
            manager,
          );
      }

      return {
        message: isNewIncident
          ? "Đã tạo sự cố mới"
          : "Đã ghi nhận phản ánh (Trùng với sự cố đang xử lý)",
        incident: mainIncident,
        report: savedReport,
        assignedDepartment: null,
        ai_suggestion: mainIncident.ai_suggestion_reason,
        location: {
          address: reported_address ?? null,
          latitude,
          longitude,
          source: location_source ?? "GPS",
        },
        media_attached: true,
      };
    });
  }

  async endorseIncident(userId: string, incidentId: string) {
    return AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const reportRepo = manager.getRepository(IncidentReport);

      const incident = await incidentRepo.findOne({
        where: { id: incidentId },
        relations: { incident_type: true },
        lock: { mode: "pessimistic_write" },
      });

      if (!incident) {
        throw {
          statusCode: 404,
          message: "Không tìm thấy sự cố cần đồng phản ánh",
        };
      }

      if (["RESOLVED", "REJECTED", "CANCELLED"].includes(incident.status)) {
        throw {
          statusCode: 400,
          message: "Sự cố này đã kết thúc, không thể đồng phản ánh",
        };
      }

      // Kiểm tra xem người dùng đã báo cáo hoặc đã đồng phản ánh sự cố này chưa
      const existingReport = await reportRepo.findOne({
        where: { incident_id: incidentId, reporter_id: userId },
      });

      if (existingReport) {
        return {
          already_endorsed: true,
          report_count: incident.report_count,
          priority_score: incident.priority_score,
          priority_level: incident.priority_level,
          message: "Bạn đã gửi phản ánh hoặc đồng phản ánh sự cố này rồi!",
        };
      }

      // Tạo bản ghi đồng phản ánh
      const coords = (incident.location as any)?.coordinates ?? [106.66, 10.76];
      const newReport = reportRepo.create({
        incident_id: incident.id,
        reporter_id: userId,
        description: "Đồng phản ánh từ cộng đồng (+1)",
        reported_location: { type: "Point", coordinates: coords },
        reported_severity: incident.severity_level,
      });
      await reportRepo.save(newReport);

      // Tăng số lượng báo cáo
      incident.report_count = (incident.report_count || 1) + 1;

      // Tính lại điểm ưu tiên
      const scoreData = await this.deps.scoringService.calculateConfigured(
        incident.incident_type?.type_priority_level || 3,
        incident.severity_level || 3,
        incident.report_count,
        incident.created_at,
        manager,
      );
      incident.priority_score = scoreData.score;
      incident.priority_level = scoreData.level;

      await incidentRepo.save(incident);

      await this.deps.auditLogService.record(
        {
          user_id: userId,
          action: "INCIDENT_ENDORSED",
          entity_type: "incident",
          entity_id: incident.id,
          details: {
            new_report_count: incident.report_count,
            priority_score: incident.priority_score,
          },
        },
        manager,
      );

      return {
        already_endorsed: false,
        report_count: incident.report_count,
        priority_score: incident.priority_score,
        priority_level: incident.priority_level,
        message: "Đã ghi nhận đóng góp đồng phản ánh (+1) của bạn!",
      };
    });
  }
}
