import { ILike, IsNull } from 'typeorm';
import { AppDataSource } from '../../database/data-source';
import { Incident } from './incident.entity';
import { IncidentReport } from '../incident-reports/incident-report.entity';
import { IncidentMedia } from '../media/media.entity';
import { IncidentType } from '../incident-types/incident-type.entity';
import { IncidentAssignment } from '../assignments/assignment.entity';
import { IncidentUpdate } from '../incident-updates/incident-update.entity';
import { Department } from '../departments/department.entity';

import { DuplicateDetectionService } from '../../algorithms/duplicate-detection/duplicate-detection.service';
import { DepartmentAssignmentService } from '../../algorithms/department-assignment/department-assignment.service';
import { PriorityScoringService } from '../../algorithms/priority-scoring/priority-scoring.service';
import { AiService } from '../../common/services/ai.service';
import { canOfficerTransitionIncident, canTransitionIncident } from '../../common/constants/incident-status';
import { canViewInternalIncidentData, IncidentViewer } from './incident.policy';
import { NotificationService } from '../notifications/notification.service';
import { AuditLogService } from '../audit-logs/audit-log.service';

type UploadedMedia = { url: string; type: string; size: number; storage_key: string };
const normalizeMedia = (item: string | UploadedMedia): UploadedMedia => typeof item === 'string'
  ? { url: item, type: 'image/jpeg', size: 1, storage_key: item.split('/').pop() || `legacy_${Date.now()}` }
  : item;

export class IncidentService {
  private incidentRepo = AppDataSource.getRepository(Incident);
  private reportRepo = AppDataSource.getRepository(IncidentReport);
  private mediaRepo = AppDataSource.getRepository(IncidentMedia);
  private typeRepo = AppDataSource.getRepository(IncidentType);
  private assignmentRepo = AppDataSource.getRepository(IncidentAssignment);
  private updateRepo = AppDataSource.getRepository(IncidentUpdate);

  private duplicateService = new DuplicateDetectionService();
  private assignmentService = new DepartmentAssignmentService();
  private scoringService = new PriorityScoringService();
  private aiService = new AiService();
  private notificationService = new NotificationService();
  private auditLogService = new AuditLogService();

  async analyzeReport(data: { description: string; media_urls: UploadedMedia[] }) {
    return this.aiService.analyzeIncidentImages(data.media_urls.map(item => item.url), data.description);
  }

  async listManualReview(query: { page?: unknown; limit?: unknown }) {
    const page = Math.max(Number(query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
    const qb = this.reportRepo.createQueryBuilder('report')
      .innerJoinAndSelect('report.incident', 'incident')
      .leftJoinAndSelect('incident.incident_type', 'type')
      .leftJoinAndMapMany('report.media', IncidentMedia, 'media', 'media.report_id=report.id')
      .where('report.requires_manual_review=TRUE')
      .orderBy('report.created_at', 'ASC')
      .skip((page - 1) * limit).take(limit);
    const [data, total] = await qb.getManyAndCount();
    return { data, meta: { page, limit, total, total_pages: Math.ceil(total / limit) } };
  }

  async reviewReport(reportId: string, reviewerId: string, data: { decision: 'APPROVE' | 'REJECT'; incident_type_id?: string; note: string }) {
    return AppDataSource.transaction(async (manager) => {
      const reportRepo = manager.getRepository(IncidentReport);
      const incidentRepo = manager.getRepository(Incident);
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const report = await reportRepo.findOne({ where: { id: reportId }, lock: { mode: 'pessimistic_write' } });
      if (!report) throw { statusCode: 404, message: 'Không tìm thấy phản ánh cần kiểm duyệt' };
      if (!report.requires_manual_review) throw { statusCode: 409, message: 'Phản ánh này đã được kiểm duyệt' };
      const incident = await incidentRepo.findOne({ where: { id: report.incident_id }, lock: { mode: 'pessimistic_write' } });
      if (!incident) throw { statusCode: 404, message: 'Không tìm thấy sự cố' };

      report.requires_manual_review = false;
      report.ai_analysis = { ...(report.ai_analysis ?? {}), review: { decision: data.decision, note: data.note, reviewer_id: reviewerId, reviewed_at: new Date().toISOString() } };
      await reportRepo.save(report);
      await manager.query(`INSERT INTO ai_feedbacks(report_id,actor_id,source,ai_incident_type,confirmed_incident_type_id,ai_severity,confirmed_severity,decision,note) VALUES($1,$2,'ADMIN_REVIEW',$3,$4,$5,$6,$7,$8)`,[
        report.id,reviewerId,(report.ai_analysis as any)?.suggested_incident_type??null,data.incident_type_id??null,
        (report.ai_analysis as any)?.suggested_severity??null,report.reported_severity??null,data.decision,data.note
      ]);

      if (data.decision === 'REJECT') {
        const otherReports = await reportRepo.count({ where: { incident_id: incident.id, requires_manual_review: false } });
        if (otherReports <= 1 && incident.status === 'PENDING_ASSIGNMENT') incident.status = 'REJECTED';
        await incidentRepo.save(incident);
        await this.notificationService.create({ user_id: report.reporter_id, incident_id: incident.id, type: 'REPORT_REJECTED', title: 'Phản ánh chưa được chấp nhận', message: data.note, data: { incident_id: incident.id } }, manager);
      } else {
        const type = await manager.getRepository(IncidentType).findOne({ where: { id: data.incident_type_id!, is_active: true } });
        if (!type) throw { statusCode: 404, message: 'Loại sự cố không tồn tại hoặc đã ngừng sử dụng' };
        incident.incident_type_id = type.id;
        const coordinates = incident.location.coordinates;
        const assigned = await this.assignmentService.findAssignedDepartment(coordinates[0], coordinates[1], type.id, manager);
        if (assigned && incident.status === 'PENDING_ASSIGNMENT') {
          await assignmentRepo.save(assignmentRepo.create({ incident_id: incident.id, department_id: assigned.id, assignment_method: assigned.assignment_method, workload_at_assignment: assigned.workload, distance_m: assigned.distance_m }));
          incident.status = 'ASSIGNED';
          await this.notificationService.notifyDepartment(incident.id, assigned.id, manager);
        }
        await incidentRepo.save(incident);
        if (incident.status === 'PENDING_ASSIGNMENT') {
          await this.notificationService.notifyAdmins({
            eventKey: `review-approved:${report.id}`, type: 'INCIDENT_PENDING_ASSIGNMENT',
            incidentId: incident.id, title: 'Phản ánh đã duyệt cần phân công',
            message: 'Chưa xác định được đơn vị phù hợp. Vui lòng phân công thủ công.',
            actionPath: `/incidents/${incident.id}`, actionLabel: 'Mở và phân công',
          }, manager);
        }
        await this.notificationService.create({ user_id: report.reporter_id, incident_id: incident.id, type: 'REPORT_APPROVED', title: 'Phản ánh đã được xác minh', message: 'Phản ánh đã được chuyển sang quy trình xử lý.', data: { incident_id: incident.id } }, manager);
      }
      await this.auditLogService.record({ user_id: reviewerId, action: `REPORT_REVIEW_${data.decision}`, entity_type: 'incident_report', entity_id: report.id, details: { incident_id: incident.id, note: data.note, incident_type_id: data.incident_type_id } }, manager);
      return { report_id: report.id, incident_id: incident.id, decision: data.decision, incident_status: incident.status };
    });
  }

  /**
   * Tạo phản ánh mới (áp dụng 3 thuật toán)
   */
  async createReport(reporterId: string, data: any) {
    let { incident_type_id, description, longitude, latitude, reported_address, location_source, reported_severity, media_urls, ai_confirmation, ai_analysis } = data;
    let aiAnalysis: any = ai_analysis ?? null;

    // Nếu client ĐÃ phân tích ở bước trước và người dùng đã duyệt/xác nhận thì dùng luôn kết quả đó,
    // KHÔNG gọi lại AI để tránh tốn tài nguyên và ghi đè nội dung người dùng đã duyệt.
    if (!aiAnalysis && media_urls && media_urls.length > 0) {
      console.log('Chưa có kết quả AI từ client, đang phân tích ảnh mới...');
      const imageUrls = (media_urls as Array<string | UploadedMedia>)
        .map(item => typeof item === 'string' ? item : item.url)
        .filter(Boolean);
      aiAnalysis = await this.aiService.analyzeIncidentImages(imageUrls, description);
    }

    if (aiAnalysis) {
      aiAnalysis = {
        ...aiAnalysis,
        original_reason: ai_confirmation.suggested_summary ?? aiAnalysis.original_reason ?? aiAnalysis.reason,
        reason: ai_confirmation.confirmed_summary,
        user_edited_reason: ai_confirmation.summary_edited === true,
      };
      // 2. Tự động điền mức độ nếu user chưa chọn
      if (!reported_severity && aiAnalysis.suggested_severity) {
        reported_severity = aiAnalysis.suggested_severity;
      }
      
      // 3. Tự động tìm Loại sự cố nếu user chưa chọn (User trải nghiệm 1-click)
      if (!incident_type_id && aiAnalysis.suggested_incident_type) {
        const foundType = await this.typeRepo.findOne({ 
          where: { name: ILike(`%${aiAnalysis.suggested_incident_type}%`) } 
        });
        if (foundType) {
          incident_type_id = foundType.id;
        }
      }
      if (!incident_type_id && aiAnalysis.requires_manual_review) {
        const fallbackType = await this.typeRepo.findOne({ where: { name: ILike('%Khác%'), is_active: true } });
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
            confirmed_incident_type_id: ai_confirmation.confirmed_incident_type_id,
            confirmed_severity: ai_confirmation.confirmed_severity,
            confirmed_at: ai_confirmation.confirmed_at,
            recorded_at: new Date().toISOString(),
          },
        };
      }
    }

    if (!incident_type_id) {
       throw { statusCode: 400, message: 'Thiếu ID loại sự cố. Vui lòng chọn thủ công nếu AI không nhận ra.' };
    }

    return AppDataSource.transaction(async (manager) => {
    const incidentRepo = manager.getRepository(Incident);
    const reportRepo = manager.getRepository(IncidentReport);
    const mediaRepo = manager.getRepository(IncidentMedia);
    const typeRepo = manager.getRepository(IncidentType);
    const assignmentRepo = manager.getRepository(IncidentAssignment);

    // Khóa theo loại + ô địa lý khoảng 100 m để serialize các báo cáo có khả năng trùng.
    const lockKey = `${incident_type_id}:${longitude.toFixed(3)}:${latitude.toFixed(3)}`;
    await manager.query('SELECT pg_advisory_xact_lock(hashtext($1))', [lockKey]);

    // 1. Kiểm tra Loại sự cố
    const incidentType = await typeRepo.findOne({ where: { id: incident_type_id } });
    if (!incidentType) throw { statusCode: 404, message: 'Loại sự cố không tồn tại' };

    // 2. Thuật toán: Phát hiện trùng lặp
    const duplicateIncident = await this.duplicateService.findDuplicate(
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
          message: 'Bạn đã báo cáo sự cố này rồi. Cảm ơn bạn!',
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
      const scoreData = await this.scoringService.calculateConfigured(
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
      const scoreData = await this.scoringService.calculateConfigured(incidentType.type_priority_level,reported_severity || incidentType.default_severity,1,new Date(),manager);
      
      const newIncident = incidentRepo.create({
        incident_type_id,
        description,
        location: { type: 'Point', coordinates: [longitude, latitude] },
        severity_level: reported_severity || incidentType.default_severity,
        status: 'PENDING_ASSIGNMENT',
        priority_score: scoreData.score,
        priority_level: scoreData.level,
        report_count: 1
      });

      mainIncident = await incidentRepo.save(newIncident);
      incidentId = mainIncident.id;
    }

    // 3. Tạo record IncidentReport (Dành riêng cho User này)
    const newReport = reportRepo.create({
      incident_id: incidentId,
      reporter_id: reporterId,
      description,
      reported_location: { type: 'Point', coordinates: [longitude, latitude] },
      reported_address: reported_address ?? null,
      location_source: location_source ?? 'GPS',
      reported_severity,
      ai_analysis: aiAnalysis,
      requires_manual_review: aiAnalysis?.requires_manual_review===true,
      duplicate_score: duplicateIncident ? (duplicateIncident as any).duplicateEvidence?.score ?? null : null,
      duplicate_distance_m: duplicateIncident ? (duplicateIncident as any).duplicateEvidence?.distance_m ?? null : null,
      duplicate_time_minutes: duplicateIncident ? (duplicateIncident as any).duplicateEvidence?.time_minutes ?? null : null,
      duplicate_evidence: duplicateIncident ? (duplicateIncident as any).duplicateEvidence ?? null : null,
    });
    const savedReport = await reportRepo.save(newReport);
    await manager.query(`INSERT INTO ai_feedbacks(report_id,actor_id,source,ai_incident_type,confirmed_incident_type_id,ai_severity,confirmed_severity,decision,note) VALUES($1,$2,'CITIZEN_CONFIRMATION',$3,$4,$5,$6,$7,$8)`,[
      savedReport.id,reporterId,aiAnalysis?.suggested_incident_type??null,incident_type_id,
      aiAnalysis?.suggested_severity??null,reported_severity??null,
      aiAnalysis?.suggested_incident_type===ai_confirmation.suggested_incident_type&&aiAnalysis?.suggested_severity===ai_confirmation.confirmed_severity&&!ai_confirmation.summary_edited?'CONFIRMED':'CORRECTED',
      ai_confirmation.summary_edited?'Người dân đã chỉnh tóm tắt AI trước khi xác nhận':'Người dân giữ nguyên tóm tắt AI và xác nhận trước khi gửi'
    ]);
    await this.notificationService.create({user_id:reporterId,incident_id:incidentId,type:isNewIncident?'REPORT_RECEIVED':'REPORT_MERGED',title:'Đã ghi nhận phản ánh',message:isNewIncident?'Phản ánh của bạn đã được tiếp nhận.':'Phản ánh đã được gộp với sự cố đang xử lý.',data:{incident_id:incidentId}},manager);

    if (savedReport.requires_manual_review) {
      await this.notificationService.notifyAdmins({
        eventKey: `manual-review:${savedReport.id}`, type: 'REPORT_PENDING_REVIEW',
        incidentId, title: 'Phản ánh cần kiểm duyệt',
        message: `Có phản ánh cần kiểm tra ảnh, loại và mức độ: ${description.slice(0, 160)}`,
        actionPath: '/manual-review', actionLabel: 'Mở kiểm duyệt',
        data: { report_id: savedReport.id },
      }, manager);
    }

    // 4. Lưu Media
    if (media_urls && media_urls.length > 0) {
      const mediaRecords = media_urls.map((raw: string | UploadedMedia) => { const media = normalizeMedia(raw); return mediaRepo.create({
        incident_id: incidentId,
        report_id: savedReport.id,
        uploaded_by: reporterId,
        media_type: media.type.startsWith('video/') ? 'VIDEO' : 'IMAGE',
        file_url: media.url,
        storage_key: media.storage_key,
        mime_type: media.type,
        file_size: media.size,
      }); });
      await mediaRepo.save(mediaRecords);
    }

    // Tạo tối đa một cảnh báo cho mỗi user + sự cố. Hàm notification
    // tự chống trùng nên vẫn gọi khi phản ánh được gộp vào incident đã có.
    await this.notificationService.notifyInterestedAreas(incidentId, reporterId, manager);

    // 5. Thuật toán: AI Gợi ý phân công cán bộ & đơn vị chuyên trách
    if (isNewIncident) {
      const officerSuggestion = await new DepartmentAssignmentService().suggestOfficerAssignment(
        longitude,
        latitude,
        incident_type_id,
        manager,
        description,
      );
      if (officerSuggestion) {
        mainIncident.ai_suggested_department_id = officerSuggestion.department_id;
        mainIncident.ai_suggested_officer_id = officerSuggestion.officer_id;
        mainIncident.ai_suggestion_reason = officerSuggestion.reason;
        mainIncident.ai_suggestion_confidence = officerSuggestion.confidence as any;
        await incidentRepo.save(mainIncident);
      }
      const incidentType = await manager.getRepository(IncidentType).findOne({
        where: { id: incident_type_id },
      });
      if (!savedReport.requires_manual_review) await this.notificationService.notifyAdminsPendingAssignment(
        incidentId,
        incidentType?.name ?? 'Sự cố đô thị',
        description,
        reported_address ?? null,
        manager,
      );
    }

    return {
      message: isNewIncident ? 'Đã tạo sự cố mới' : 'Đã ghi nhận phản ánh (Trùng với sự cố đang xử lý)',
      incident: mainIncident,
      report: savedReport,
      assignedDepartment: null,
      ai_suggestion: mainIncident.ai_suggestion_reason,
      location: {
        address: reported_address ?? null,
        latitude,
        longitude,
        source: location_source ?? 'GPS',
      },
      media_attached: true
    };
    });
  }

  /**
   * Lấy danh sách sự cố (phân trang)
   */
  async findAll(query: any) {
    const page = Math.max(Number(query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
    const { status, incident_type_id, priority, q, manual_review, sort_by, sort_order } = query;
    const skip = (page - 1) * limit;

    const qb = this.incidentRepo.createQueryBuilder('incident')
      .leftJoinAndSelect('incident.incident_type', 'type');

    const orderDirection = (sort_order?.toUpperCase() === 'ASC') ? 'ASC' : 'DESC';

    if (sort_by === 'priority') {
      qb.orderBy('incident.priority_score', orderDirection)
        .addOrderBy('incident.created_at', 'DESC');
    } else if (sort_by === 'report_count') {
      qb.orderBy('incident.report_count', orderDirection)
        .addOrderBy('incident.created_at', 'DESC');
    } else if (sort_by === 'status') {
      qb.orderBy('incident.status', orderDirection)
        .addOrderBy('incident.created_at', 'DESC');
    } else {
      // Mặc định: Sự cố mới nhất lên đầu (created_at DESC)
      qb.orderBy('incident.created_at', orderDirection)
        .addOrderBy('incident.priority_score', 'DESC');
    }

    qb.skip(skip).take(limit);

    if (status) qb.andWhere('incident.status = :status', { status });
    if (incident_type_id) qb.andWhere('incident.incident_type_id = :incident_type_id', { incident_type_id });
    if (priority) qb.andWhere('incident.priority_level = :priority', { priority });
    if (q) qb.andWhere('(incident.description ILIKE :q OR type.name ILIKE :q)', { q: `%${q}%` });
    if (manual_review === 'true') qb.andWhere(`EXISTS (SELECT 1 FROM incident_reports report WHERE report.incident_id=incident.id AND report.requires_manual_review=TRUE)`);

    const [data, total] = await qb.getManyAndCount();
    const ids = data.map((incident) => incident.id);
    const coverRows = ids.length ? await this.mediaRepo.createQueryBuilder('media')
      .distinctOn(['media.incident_id'])
      .select('media.incident_id', 'incident_id')
      .addSelect('media.file_url', 'file_url')
      .where('media.incident_id IN (:...ids)', { ids })
      .andWhere("media.media_type = 'IMAGE'")
      .orderBy('media.incident_id')
      .addOrderBy('media.created_at', 'ASC')
      .getRawMany() : [];
    const covers = new Map(coverRows.map((row) => [row.incident_id, row.file_url]));

    const deptRows = ids.length ? await this.assignmentRepo.createQueryBuilder('assignment')
      .innerJoin(Department, 'dept', 'dept.id = assignment.department_id')
      .where('assignment.incident_id IN (:...ids)', { ids })
      .orderBy('CASE WHEN assignment.ended_at IS NULL THEN 0 ELSE 1 END', 'ASC')
      .addOrderBy('assignment.assigned_at', 'DESC')
      .select('assignment.incident_id', 'incident_id')
      .addSelect('dept.name', 'department_name')
      .getRawMany() : [];
    const depts = new Map(deptRows.map((r: any) => [r.incident_id, r.department_name]));

    return { 
      data: data.map((incident) => ({ 
        ...incident, 
        cover_url: covers.get(incident.id) ?? null,
        assigned_department: depts.get(incident.id) ? { name: depts.get(incident.id) } : null
      })), 
      total, 
      page, 
      limit, 
      totalPages: Math.ceil(total / limit) 
    };
  }

  /**
   * Lấy chi tiết sự cố
   */
  async findOne(id: string) {
    const incident = await this.incidentRepo.findOne({
      where: { id },
      relations: { incident_type: true },
    });
    if (!incident) throw { statusCode: 404, message: 'Không tìm thấy sự cố' };

    const [allMedia, rawUpdates, assignment, latestReport, reportWithAi] = await Promise.all([
      this.mediaRepo.find({ where: { incident_id: id }, order: { created_at: 'ASC' } }),
      this.updateRepo.find({ where: { incident_id: id }, order: { created_at: 'ASC' } }),
      this.assignmentRepo.createQueryBuilder('assignment')
        .leftJoin(Department, 'department', 'department.id = assignment.department_id')
        .leftJoin('users', 'officer', 'officer.id = assignment.accepted_by')
        .leftJoin('users', 'assigned_officer', 'assigned_officer.id = assignment.assigned_officer_id')
        .where('assignment.incident_id = :id', { id })
        .orderBy('CASE WHEN assignment.ended_at IS NULL THEN 0 ELSE 1 END', 'ASC')
        .addOrderBy('assignment.assigned_at', 'DESC')
        .select([
          'assignment.id AS id',
          'assignment.department_id AS department_id',
          'assignment.assigned_officer_id AS assigned_officer_id',
          'assignment.accepted_by AS accepted_by',
          'assignment.assignment_method AS assignment_method',
          'assignment.reason AS reason',
          'assignment.assigned_at AS assigned_at',
          'assignment.accepted_at AS accepted_at',
          'department.name AS department_name',
          'officer.full_name AS officer_name',
          'officer.phone AS officer_phone',
          'assigned_officer.full_name AS assigned_officer_name',
          'assigned_officer.phone AS assigned_officer_phone',
        ])
        .getRawOne(),
      this.reportRepo.findOne({ where: { incident_id: id }, order: { created_at: 'DESC' } }),
      this.reportRepo.createQueryBuilder('report')
        .where('report.incident_id = :id AND report.ai_analysis IS NOT NULL', { id })
        .orderBy('report.created_at', 'DESC')
        .getOne(),
    ]);

    const updates = rawUpdates.map(u => ({
      ...u,
      media: allMedia.filter(m => m.update_id === u.id).map(m => ({ id: m.id, file_url: m.file_url, media_type: m.media_type })),
      media_urls: allMedia.filter(m => m.update_id === u.id).map(m => m.file_url),
    }));

    const reportMedia = allMedia.filter(m => !m.update_id);
    const officerMedia = allMedia.filter(m => m.update_id);
    const targetReport = reportWithAi ?? latestReport;

    let aiSuggestion: any = null;
    if (incident.ai_suggested_department_id || incident.ai_suggested_officer_id) {
      const [deptRows, officerRows] = await Promise.all([
        incident.ai_suggested_department_id ? AppDataSource.query('SELECT id, name, phone FROM departments WHERE id = $1', [incident.ai_suggested_department_id]) : [],
        incident.ai_suggested_officer_id ? AppDataSource.query(`
          SELECT u.id, u.full_name, u.phone,
            COALESCE((
              SELECT COUNT(*)::int
              FROM incident_assignments a
              JOIN incidents i ON i.id = a.incident_id
              WHERE a.accepted_by = u.id AND a.ended_at IS NULL AND i.status NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED')
            ), 0)::int AS active_workload
          FROM users u WHERE u.id = $1
        `, [incident.ai_suggested_officer_id]) : [],
      ]);
      aiSuggestion = {
        department_id: incident.ai_suggested_department_id,
        department_name: deptRows[0]?.name ?? null,
        officer_id: incident.ai_suggested_officer_id,
        officer_name: officerRows[0]?.full_name ?? null,
        officer_phone: officerRows[0]?.phone ?? null,
        active_workload: officerRows[0]?.active_workload ?? 0,
        reason: incident.ai_suggestion_reason,
        confidence: incident.ai_suggestion_confidence ? Number(incident.ai_suggestion_confidence) : 0.95,
      };
    } else if (incident.status === 'PENDING_ASSIGNMENT') {
      const coords = (incident.location as any).coordinates;
      aiSuggestion = await new DepartmentAssignmentService().suggestOfficerAssignment(
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
      duplicate_evidence: targetReport?.duplicate_evidence ?? null
    };
  }

  async reanalyzeIncident(id: string) {
    const incident = await this.incidentRepo.findOne({ where: { id } });
    if (!incident) throw { statusCode: 404, message: 'Không tìm thấy sự cố' };

    const mediaList = await this.mediaRepo.find({ where: { incident_id: id }, order: { created_at: 'ASC' } });
    const imageUrls = mediaList.map(m => m.file_url).filter(Boolean);
    if (!imageUrls.length) {
      throw { statusCode: 400, message: 'Sự cố không có hình ảnh để AI phân tích' };
    }

    const aiAnalysis = await this.aiService.analyzeIncidentImages(imageUrls, incident.description);

    let report = await this.reportRepo.findOne({ where: { incident_id: id }, order: { created_at: 'DESC' } });
    if (report) {
      report.ai_analysis = aiAnalysis;
      await this.reportRepo.save(report);
    }
    return aiAnalysis;
  }

  async findOneForViewer(id: string, viewer?: IncidentViewer) {
    const incident = await this.findOne(id);
    const [reports, assignments] = await Promise.all([
      this.reportRepo.find({ where: { incident_id: id }, select: { reporter_id: true } }),
      this.assignmentRepo.find({ where: { incident_id: id }, select: { department_id: true } }),
    ]);
    const isMine = Boolean(viewer?.id && reports.some((report) => report.reporter_id === viewer.id));
    const canViewInternal = canViewInternalIncidentData(
      viewer,
      reports.map((report) => report.reporter_id),
      assignments.map((assignment) => assignment.department_id),
    );
    if (viewer?.role === 'OFFICER' && !canViewInternal) {
      throw { statusCode: 403, message: 'Sự cố không thuộc đơn vị của bạn' };
    }
    const resolvedUpdate = incident.updates?.find((update: any) => update.new_status === 'RESOLVED');
    const verificationNote = resolvedUpdate?.note ?? null;

    if (canViewInternal && viewer?.role !== 'CITIZEN') return { ...incident, verification_note: verificationNote, is_mine: isMine };
    if (canViewInternal && viewer?.role === 'CITIZEN') {
      const updates = incident.updates.filter((update: any) => update.visibility !== 'INTERNAL');
      const updateIds = new Set(updates.map((update: any) => update.id));
      return {
        ...incident,
        verification_note: verificationNote,
        updates,
        officer_media: incident.officer_media.filter((media: any) => !media.update_id || updateIds.has(media.update_id)),
        is_mine: isMine,
      };
    }
    const { assignment: _assignment, ...publicIncident } = incident;
    const publicUpdates = publicIncident.updates.filter((update: any) => update.visibility !== 'INTERNAL');
    const publicUpdateIds = new Set(publicUpdates.map((update: any) => update.id));
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
      officer_media: publicIncident.officer_media.filter((media: any) => !media.update_id || publicUpdateIds.has(media.update_id)),
      is_mine: isMine,
    };
  }

  /**
   * Lấy phản ánh của user
   */
  async getMyReports(userId: string) {
    const reports = await this.reportRepo.find({
      where: { reporter_id: userId },
      relations: { incident: { incident_type: true } },
      order: { created_at: 'DESC' },
    });

    if (reports.length === 0) return [];

    const reportIds = reports.map((report) => report.id);
    const media = await this.mediaRepo.createQueryBuilder('media')
      .where('media.report_id IN (:...reportIds)', { reportIds })
      .orderBy('media.created_at', 'ASC')
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

  /**
   * Truy vấn sự cố theo Bounding Box (Bản đồ)
   */
  async getByBoundingBox(minLng: number, minLat: number, maxLng: number, maxLat: number) {
    return this.incidentRepo.createQueryBuilder('incident')
      .leftJoinAndSelect('incident.incident_type', 'type')
      .where(`ST_MakeEnvelope(:minLng, :minLat, :maxLng, :maxLat, 4326) ~ incident.location::geometry`, {
        minLng, minLat, maxLng, maxLat
      })
      .getMany();
  }

  /**
   * Cập nhật trạng thái sự cố (Dành cho Cán bộ)
   */
  async updateStatus(id: string, userId: string, role: string, departmentId: string | null, data: any) {
    const { status, note, media_urls } = data;
    const updateLog = await AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const updateRepo = manager.getRepository(IncidentUpdate);
      const mediaRepo = manager.getRepository(IncidentMedia);
      const incident = await incidentRepo.findOne({
        where: { id },
        lock: { mode: 'pessimistic_write' },
      });
      if (!incident) throw { statusCode: 404, message: 'Không tìm thấy sự cố' };

      if (role === 'OFFICER') {
        let assignment = await assignmentRepo.findOne({
          where: { incident_id: id, accepted_by: userId, ended_at: IsNull() },
          lock: { mode: 'pessimistic_write' },
        });
        if (!assignment && departmentId) {
          const deptAssignment = await assignmentRepo.findOne({
            where: { incident_id: id, department_id: departmentId, accepted_by: IsNull(), ended_at: IsNull() },
            lock: { mode: 'pessimistic_write' },
          });
          if (deptAssignment) {
            deptAssignment.accepted_by = userId;
            deptAssignment.accepted_at = new Date();
            assignment = await assignmentRepo.save(deptAssignment);
          }
        }
        if (!assignment || assignment.department_id !== departmentId) {
          throw { statusCode: 403, message: 'Bạn phải tiếp nhận nhiệm vụ này trước khi cập nhật' };
        }
        if (!assignment.accepted_at) {
          assignment.accepted_at = new Date();
          await assignmentRepo.save(assignment);
        }
      }
      if (!canTransitionIncident(incident.status, status)) {
        throw { statusCode: 409, message: `Không thể chuyển từ ${incident.status} sang ${status}` };
      }
      if (role === 'OFFICER' && !canOfficerTransitionIncident(incident.status, status)) {
        throw { statusCode: 403, message: 'Cán bộ chỉ được chuyển sang đang xử lý hoặc hoàn thành theo đúng quy trình' };
      }
      if (role === 'OFFICER' && status === 'PENDING_VERIFICATION') {
        const [missing] = await manager.query(`SELECT COUNT(*)::int count FROM incident_type_checklist_items c LEFT JOIN incident_checklist_results r ON r.checklist_item_id=c.id AND r.incident_id=$1 WHERE c.incident_type_id=$2 AND c.is_active=TRUE AND c.is_required=TRUE AND COALESCE(r.completed,FALSE)=FALSE`, [id, incident.incident_type_id]);
        if (Number(missing?.count ?? 0) > 0) {
          throw { statusCode: 409, message: `Còn ${missing.count} bước checklist bắt buộc chưa hoàn thành` };
        }
      }

      const oldStatus = incident.status;
      incident.status = status;
      incident.resolved_at = status === 'RESOLVED' ? new Date() : null;
      await incidentRepo.save(incident);

      if (['RESOLVED', 'REJECTED', 'CANCELLED'].includes(status)) {
        await assignmentRepo.update({ incident_id: id, ended_at: IsNull() }, { ended_at: new Date() });
      }

      const savedLog = await updateRepo.save(updateRepo.create({
        incident_id: id,
        updated_by: userId,
        old_status: oldStatus,
        new_status: status,
        note,
      }));
      const statusLabel: Record<string, string> = { IN_PROGRESS: 'đang xử lý', PENDING_VERIFICATION: 'đang chờ nghiệm thu', RESOLVED: 'đã hoàn thành', REJECTED: 'đã bị từ chối', CANCELLED: 'đã bị hủy' };
      const reason = ['REJECTED', 'CANCELLED'].includes(status) ? ` Lý do: ${note}` : '';
      await this.notificationService.notifyReporters(id,`STATUS_${status}`,'Trạng thái phản ánh đã thay đổi',`Phản ánh của bạn ${statusLabel[status] ?? status}.${reason}`,manager);
      if (media_urls?.length) {
        await mediaRepo.save(media_urls.map((raw: string | UploadedMedia) => { const media = normalizeMedia(raw); return mediaRepo.create({
          incident_id: id,
          update_id: savedLog.id,
          uploaded_by: userId,
          media_type: media.type.startsWith('video/') ? 'VIDEO' : 'IMAGE',
          file_url: media.url,
          storage_key: media.storage_key,
          mime_type: media.type,
          file_size: media.size,
        }); }));
      }
      if (status === 'PENDING_VERIFICATION') {
        await this.notificationService.notifyAdmins({
          eventKey: `verification:${savedLog.id}`, type: 'INCIDENT_PENDING_VERIFICATION',
          incidentId: id, title: 'Có hồ sơ chờ nghiệm thu',
          message: `Cán bộ đã gửi kết quả xử lý: ${String(note ?? '').slice(0, 180)}`,
          actionPath: `/incidents/${id}`, actionLabel: 'Mở nghiệm thu',
          data: { update_id: savedLog.id, status },
        }, manager);
      }
      return savedLog;
    });

    return { incident: await this.findOne(id), updateLog };
  }

  async verifyIncident(id: string, adminId: string, data: { decision: 'APPROVE' | 'REWORK'; note: string }) {
    await AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const updateRepo = manager.getRepository(IncidentUpdate);
      const incident = await incidentRepo.findOne({ where: { id }, lock: { mode: 'pessimistic_write' } });
      if (!incident) throw { statusCode: 404, message: 'Không tìm thấy sự cố' };
      if (incident.status !== 'PENDING_VERIFICATION') {
        throw { statusCode: 409, message: 'Sự cố chưa ở trạng thái chờ nghiệm thu' };
      }
      const assignment = await assignmentRepo.findOne({
        where: { incident_id: id, ended_at: IsNull() },
        lock: { mode: 'pessimistic_write' },
      });
      const nextStatus = data.decision === 'APPROVE' ? 'RESOLVED' : 'IN_PROGRESS';
      incident.status = nextStatus;
      incident.resolved_at = nextStatus === 'RESOLVED' ? new Date() : null;
      await incidentRepo.save(incident);
      if (nextStatus === 'RESOLVED') {
        await assignmentRepo.update({ incident_id: id, ended_at: IsNull() }, { ended_at: new Date() });
      }
      await updateRepo.save(updateRepo.create({
        incident_id: id,
        updated_by: adminId,
        old_status: 'PENDING_VERIFICATION',
        new_status: nextStatus,
        note: data.note,
      }));
      await this.auditLogService.record({
        user_id: adminId,
        action: data.decision === 'APPROVE' ? 'INCIDENT_VERIFIED' : 'INCIDENT_REWORK_REQUESTED',
        entity_type: 'incident',
        entity_id: id,
        details: { note: data.note, officer_id: assignment?.accepted_by ?? null },
      }, manager);
      if (assignment?.accepted_by) {
        await this.notificationService.create({
          user_id: assignment.accepted_by,
          incident_id: id,
          type: data.decision === 'APPROVE' ? 'WORK_VERIFIED' : 'WORK_REWORK_REQUIRED',
          title: data.decision === 'APPROVE' ? 'Kết quả đã được nghiệm thu' : 'Yêu cầu xử lý bổ sung',
          message: data.note,
          data: { incident_id: id, assignment_id: assignment.id },
        }, manager);
      }
      await this.notificationService.notifyReporters(
        id,
        `STATUS_${nextStatus}`,
        data.decision === 'APPROVE' ? 'Sự cố đã hoàn thành' : 'Sự cố đang được xử lý bổ sung',
        data.note,
        manager,
      );
    });
    return this.findOne(id);
  }

  async addProgressUpdate(
    id: string,
    officerId: string,
    departmentId: string | null,
    data: { note: string; media_urls?: Array<string | UploadedMedia>; progress_percent: number; estimated_completion_at?: string; blocker?: string; visibility: 'PUBLIC' | 'INTERNAL' },
  ) {
    const savedLog = await AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const updateRepo = manager.getRepository(IncidentUpdate);
      const mediaRepo = manager.getRepository(IncidentMedia);
      const incident = await incidentRepo.findOne({ where: { id }, lock: { mode: 'pessimistic_read' } });
      if (!incident) throw { statusCode: 404, message: 'Không tìm thấy sự cố' };
      if (incident.status !== 'IN_PROGRESS') {
        throw { statusCode: 409, message: 'Chỉ có thể báo cáo tiến độ khi sự cố đang được xử lý' };
      }
      const assignment = await assignmentRepo.findOne({
        where: { incident_id: id, accepted_by: officerId, ended_at: IsNull() },
      });
      if (!assignment || assignment.department_id !== departmentId) {
        throw { statusCode: 403, message: 'Bạn không phải cán bộ đang phụ trách nhiệm vụ này' };
      }
      const update = await updateRepo.save(updateRepo.create({
        incident_id: id,
        updated_by: officerId,
        old_status: 'IN_PROGRESS',
        new_status: 'IN_PROGRESS',
        note: data.note,
        progress_percent: data.progress_percent,
        estimated_completion_at: data.estimated_completion_at ? new Date(data.estimated_completion_at) : null,
        blocker: data.blocker?.trim() || null,
        visibility: data.visibility,
      }));
      if (data.media_urls?.length) {
        await mediaRepo.save(data.media_urls.map((raw) => {
          const media = normalizeMedia(raw);
          return mediaRepo.create({
            incident_id: id,
            update_id: update.id,
            uploaded_by: officerId,
            media_type: media.type.startsWith('video/') ? 'VIDEO' : 'IMAGE',
            file_url: media.url,
            storage_key: media.storage_key,
            mime_type: media.type,
            file_size: media.size,
          });
        }));
      }
      if (data.blocker?.trim()) {
        const [previous] = await manager.query(
          'SELECT blocker FROM incident_updates WHERE incident_id=$1 AND id<>$2 ORDER BY created_at DESC LIMIT 1',
          [id, update.id]);
        if (previous?.blocker?.trim() !== data.blocker.trim()) {
          await this.notificationService.notifyAdmins({
            eventKey: `blocker:${update.id}`, type: 'INCIDENT_BLOCKED', incidentId: id,
            title: 'Cán bộ báo khó khăn cần xem xét', message: data.blocker.trim().slice(0, 500),
            actionPath: `/incidents/${id}`, actionLabel: 'Xem và điều phối',
            data: { update_id: update.id },
          }, manager);
        }
      }
      if (data.visibility === 'PUBLIC') {
        await this.notificationService.notifyReporters(id,'PROGRESS_UPDATED','Có cập nhật tiến độ mới',data.note,manager);
      }
      return update;
    });
    return { update: savedLog, incident: await this.findOne(id) };
  }

  /**
   * Người dân đồng phản ánh (+1) cho sự cố đã có sẵn
   */
  async endorseIncident(userId: string, incidentId: string) {
    return AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const reportRepo = manager.getRepository(IncidentReport);

      const incident = await incidentRepo.findOne({
        where: { id: incidentId },
        relations: { incident_type: true },
        lock: { mode: 'pessimistic_write' },
      });

      if (!incident) {
        throw { statusCode: 404, message: 'Không tìm thấy sự cố cần đồng phản ánh' };
      }

      if (['RESOLVED', 'REJECTED', 'CANCELLED'].includes(incident.status)) {
        throw { statusCode: 400, message: 'Sự cố này đã kết thúc, không thể đồng phản ánh' };
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
          message: 'Bạn đã gửi phản ánh hoặc đồng phản ánh sự cố này rồi!',
        };
      }

      // Tạo bản ghi đồng phản ánh
      const coords = (incident.location as any)?.coordinates ?? [106.66, 10.76];
      const newReport = reportRepo.create({
        incident_id: incident.id,
        reporter_id: userId,
        description: 'Đồng phản ánh từ cộng đồng (+1)',
        reported_location: { type: 'Point', coordinates: coords },
        reported_severity: incident.severity_level,
      });
      await reportRepo.save(newReport);

      // Tăng số lượng báo cáo
      incident.report_count = (incident.report_count || 1) + 1;

      // Tính lại điểm ưu tiên
      const scoreData = await this.scoringService.calculateConfigured(
        incident.incident_type?.type_priority_level || 3,
        incident.severity_level || 3,
        incident.report_count,
        incident.created_at,
        manager,
      );
      incident.priority_score = scoreData.score;
      incident.priority_level = scoreData.level;

      await incidentRepo.save(incident);

      await this.auditLogService.record({
        user_id: userId,
        action: 'INCIDENT_ENDORSED',
        entity_type: 'incident',
        entity_id: incident.id,
        details: { new_report_count: incident.report_count, priority_score: incident.priority_score },
      }, manager);

      return {
        already_endorsed: false,
        report_count: incident.report_count,
        priority_score: incident.priority_score,
        priority_level: incident.priority_level,
        message: 'Đã ghi nhận đóng góp đồng phản ánh (+1) của bạn!',
      };
    });
  }
}
