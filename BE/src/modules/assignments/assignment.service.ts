import { AppDataSource } from '../../database/data-source';
import { IncidentAssignment } from './assignment.entity';
import { Incident } from '../incidents/incident.entity';
import { IncidentUpdate } from '../incident-updates/incident-update.entity';
import { IsNull } from 'typeorm';
import { NotificationService } from '../notifications/notification.service';
import { AuditLogService } from '../audit-logs/audit-log.service';
import { DepartmentAssignmentService } from '../../algorithms/department-assignment/department-assignment.service';
import { IncidentReport } from '../incident-reports/incident-report.entity';
import { IncidentMedia } from '../media/media.entity';

export class AssignmentService {
  private assignmentRepo = AppDataSource.getRepository(IncidentAssignment);
  private incidentRepo = AppDataSource.getRepository(Incident);
  private updateRepo = AppDataSource.getRepository(IncidentUpdate);

  async getOfficerDashboard(departmentId: string, userId: string) {
    const [summary] = await AppDataSource.query(`
      SELECT
        COUNT(*) FILTER (
          WHERE a.ended_at IS NULL AND a.accepted_by IS NULL
            AND (a.assigned_officer_id IS NULL OR a.assigned_officer_id = $2)
            AND i.status = 'ASSIGNED'
        )::int AS queue,
        COUNT(*) FILTER (
          WHERE a.ended_at IS NULL AND a.accepted_by = $2
            AND i.status IN ('ACCEPTED', 'IN_PROGRESS', 'PENDING_VERIFICATION')
        )::int AS mine,
        COUNT(*) FILTER (
          WHERE a.ended_at IS NULL
            AND (a.accepted_by = $2 OR (a.accepted_by IS NULL AND (a.assigned_officer_id IS NULL OR a.assigned_officer_id = $2)))
            AND i.priority_level IN ('HIGH', 'EMERGENCY')
        )::int AS urgent,
        COUNT(*) FILTER (
          WHERE a.ended_at IS NULL
            AND a.accepted_by = $2
            AND a.assigned_at < NOW() - INTERVAL '24 hours'
        )::int AS overdue,
        COUNT(*) FILTER (
          WHERE a.accepted_by = $2 AND a.ended_at IS NOT NULL
            AND i.status = 'RESOLVED' AND a.rejected_at IS NULL
        )::int AS completed
      FROM incident_assignments a
      JOIN incidents i ON i.id = a.incident_id
      WHERE a.department_id = $1
    `, [departmentId, userId]);

    const [latest] = await AppDataSource.query(`
      SELECT a.assigned_at, t.name AS incident_type_name, i.priority_level
      FROM incident_assignments a
      JOIN incidents i ON i.id = a.incident_id
      LEFT JOIN incident_types t ON t.id = i.incident_type_id
      WHERE a.department_id = $1 AND a.ended_at IS NULL
        AND i.status NOT IN ('RESOLVED', 'REJECTED', 'CANCELLED', 'PENDING_ASSIGNMENT')
        AND (a.accepted_by = $2 OR (a.accepted_by IS NULL AND (a.assigned_officer_id IS NULL OR a.assigned_officer_id = $2)))
      ORDER BY i.priority_score DESC NULLS LAST, a.assigned_at ASC
      LIMIT 1
    `, [departmentId, userId]);
    return { ...summary, next_priority: latest ?? null };
  }

  async getOfficerPerformance() {
    return AppDataSource.query(`
      SELECT u.id, u.full_name, u.email, u.is_active, d.name AS department_name,
        COUNT(a.id) FILTER (WHERE a.accepted_by = u.id)::int AS total_accepted,
        COUNT(a.id) FILTER (WHERE a.accepted_by = u.id AND a.ended_at IS NULL)::int AS active_tasks,
        COUNT(a.id) FILTER (WHERE a.accepted_by = u.id AND a.ended_at IS NOT NULL)::int AS completed_tasks,
        COALESCE(ROUND(AVG(EXTRACT(EPOCH FROM (a.accepted_at - a.assigned_at)) / 60)
          FILTER (WHERE a.accepted_by = u.id AND a.accepted_at IS NOT NULL)), 0)::int AS avg_accept_minutes
      FROM users u
      LEFT JOIN departments d ON d.id = u.department_id
      LEFT JOIN incident_assignments a ON a.accepted_by = u.id
      WHERE u.role = 'OFFICER'
      GROUP BY u.id, u.full_name, u.email, u.is_active, d.name
      ORDER BY active_tasks DESC, completed_tasks DESC, u.full_name ASC
    `);
  }

  async getOfficerAssignment(id: string, departmentId: string, userId: string) {
    const row = await this.assignmentRepo.createQueryBuilder('assignment')
      .innerJoin('incidents', 'incident', 'incident.id=assignment.incident_id')
      .leftJoin('incident_types', 'type', 'type.id=incident.incident_type_id')
      .leftJoin('departments', 'department', 'department.id=assignment.department_id')
      .where(`assignment.id=:id AND assignment.department_id=:departmentId
        AND (assignment.accepted_by=:userId OR assignment.rejected_by=:userId OR
          (assignment.ended_at IS NULL AND assignment.accepted_by IS NULL
            AND (assignment.assigned_officer_id IS NULL OR assignment.assigned_officer_id=:userId)))`,
        { id, departmentId, userId })
      .select([
        'assignment.id AS id','assignment.incident_id AS incident_id','assignment.department_id AS department_id',
        'assignment.assigned_officer_id AS assigned_officer_id','assignment.accepted_by AS accepted_by',
        'assignment.assignment_method AS assignment_method','assignment.reason AS reason','assignment.distance_m AS distance_m',
        'assignment.assigned_at AS assigned_at','assignment.accepted_at AS accepted_at','assignment.ended_at AS ended_at',
        'assignment.rejected_by AS rejected_by','assignment.rejection_code AS rejection_code',
        'assignment.rejection_reason AS rejection_reason','assignment.rejected_at AS rejected_at',
        `CASE
          WHEN assignment.rejected_at IS NOT NULL THEN 'REJECTED'
          WHEN assignment.ended_at IS NOT NULL AND incident.status = 'RESOLVED' THEN 'COMPLETED'
          WHEN assignment.ended_at IS NOT NULL THEN 'REASSIGNED'
          WHEN assignment.accepted_by IS NOT NULL THEN 'ACTIVE'
          ELSE 'WAITING'
        END AS assignment_state`,
        'incident.description AS description','incident.status AS status','incident.severity_level AS severity_level',
        'incident.priority_score AS priority_score','incident.priority_level AS priority_level','incident.report_count AS report_count',
        'incident.created_at AS incident_created_at','ST_Y(incident.location::geometry) AS latitude',
        'ST_X(incident.location::geometry) AS longitude','type.name AS incident_type_name',
        'department.name AS department_name',
        `(SELECT report.reported_address
          FROM incident_reports report
          WHERE report.incident_id = incident.id
            AND NULLIF(TRIM(report.reported_address), '') IS NOT NULL
          ORDER BY report.created_at ASC
          LIMIT 1) AS address`,
        '(SELECT u.progress_percent FROM incident_updates u WHERE u.incident_id=incident.id AND u.progress_percent IS NOT NULL ORDER BY u.created_at DESC LIMIT 1) AS progress_percent',
      ])
      .getRawOne();
    if (!row) throw { statusCode: 404, message: 'Nhiệm vụ không tồn tại hoặc không thuộc đơn vị của bạn' };

    const [reportWithAi, mediaRecords] = await Promise.all([
      AppDataSource.getRepository(IncidentReport).createQueryBuilder('report')
        .where('report.incident_id = :incidentId AND report.ai_analysis IS NOT NULL', { incidentId: row.incident_id })
        .orderBy('report.created_at', 'DESC')
        .getOne(),
      AppDataSource.getRepository(IncidentMedia).find({
        where: { incident_id: row.incident_id },
        order: { created_at: 'ASC' }
      }),
    ]);

    const latestReport = reportWithAi || await AppDataSource.getRepository(IncidentReport).findOne({
      where: { incident_id: row.incident_id },
      order: { created_at: 'DESC' }
    });

    return {
      ...row,
      ai_analysis: reportWithAi?.ai_analysis ?? latestReport?.ai_analysis ?? null,
      media: mediaRecords.map((media) => ({ id: media.id, file_url: media.file_url })),
      media_urls: mediaRecords.map((media) => media.file_url),
    };
  }

  async getAllAssignments(query:any={}) {
    const page=Math.max(Number(query.page)||1,1),limit=Math.min(Math.max(Number(query.limit)||20,1),100);
    const qb = this.incidentRepo.createQueryBuilder('incident')
      .leftJoin('incident_types', 'type', 'type.id = incident.incident_type_id')
      .leftJoin('incident_assignments', 'assignment', 'assignment.incident_id = incident.id AND assignment.ended_at IS NULL')
      .leftJoin(
        'incident_assignments',
        'rejected_assignment',
        `rejected_assignment.incident_id = incident.id
          AND rejected_assignment.rejected_at = (
            SELECT MAX(previous.rejected_at) FROM incident_assignments previous
            WHERE previous.incident_id = incident.id
          )`,
      )
      .leftJoin('users', 'rejecting_officer', 'rejecting_officer.id = rejected_assignment.rejected_by')
      .leftJoin('departments', 'department', 'department.id = assignment.department_id')
      .leftJoin('users', 'officer', 'officer.id = assignment.accepted_by')
      .leftJoin('users', 'assigned_officer', 'assigned_officer.id = assignment.assigned_officer_id')
      .leftJoin('departments', 'suggested_dept', 'suggested_dept.id = incident.ai_suggested_department_id')
      .leftJoin('users', 'suggested_officer', 'suggested_officer.id = incident.ai_suggested_officer_id')
      .select([
        'assignment.id AS id', 'incident.id AS incident_id',
        'assignment.department_id AS department_id', 'assignment.assignment_method AS assignment_method',
        'assignment.reason AS reason', 'assignment.assigned_at AS assigned_at',
        'assignment.assigned_officer_id AS assigned_officer_id',
        'assignment.accepted_by AS accepted_by',
        'assignment.accepted_at AS accepted_at', 'assignment.ended_at AS ended_at',
        'incident.description AS description', 'incident.status AS status',
        'incident.priority_score AS priority_score', 'incident.priority_level AS priority_level',
        'incident.created_at AS created_at',
        'incident.ai_suggested_department_id AS ai_suggested_department_id',
        'incident.ai_suggested_officer_id AS ai_suggested_officer_id',
        'incident.ai_suggestion_reason AS ai_suggestion_reason',
        'incident.ai_suggestion_confidence AS ai_suggestion_confidence',
        'suggested_dept.name AS ai_suggested_department_name',
        'suggested_officer.full_name AS ai_suggested_officer_name',
        'type.name AS incident_type_name', 'department.name AS department_name',
        'officer.full_name AS officer_name',
        'assigned_officer.full_name AS assigned_officer_name',
        'assigned_officer.phone AS assigned_officer_phone',
        'rejected_assignment.rejection_code AS rejection_code',
        'rejected_assignment.rejection_reason AS rejection_reason',
        'rejected_assignment.rejected_at AS rejected_at',
        'rejecting_officer.full_name AS rejecting_officer_name',
      ])
      .orderBy('incident.created_at', 'DESC');
    
    if(query.status) qb.andWhere('incident.status=:status',{status:query.status});
    if(query.department_id) qb.andWhere('assignment.department_id=:department_id',{department_id:query.department_id});
    
    const total=await qb.clone().getCount();
    const data=await qb.offset((page-1)*limit).limit(limit).getRawMany();
    return {data,total,page,limit,totalPages:Math.ceil(total/limit)};
  }

  /**
   * Lấy danh sách sự cố đang giao cho Đơn vị
   */
  async getDepartmentAssignments(departmentId: string, userId: string, scope: string) {
    const query = this.assignmentRepo.createQueryBuilder('assignment')
      .innerJoin('incidents', 'incident', 'incident.id = assignment.incident_id')
      .leftJoin('incident_types', 'type', 'type.id = incident.incident_type_id')
      .leftJoin('departments', 'department', 'department.id = assignment.department_id')
      .where('assignment.department_id = :departmentId', { departmentId })
      .select([
        'assignment.id AS id',
        'assignment.incident_id AS incident_id',
        'assignment.department_id AS department_id',
        'assignment.assigned_officer_id AS assigned_officer_id',
        'assignment.accepted_by AS accepted_by',
        'assignment.assignment_method AS assignment_method',
        'assignment.reason AS reason',
        'assignment.distance_m AS distance_m',
        'assignment.assigned_at AS assigned_at',
        'assignment.accepted_at AS accepted_at',
        'assignment.ended_at AS ended_at',
        'assignment.rejected_by AS rejected_by',
        'assignment.rejection_code AS rejection_code',
        'assignment.rejection_reason AS rejection_reason',
        'assignment.rejected_at AS rejected_at',
        `CASE
          WHEN assignment.rejected_at IS NOT NULL THEN 'REJECTED'
          WHEN assignment.ended_at IS NOT NULL AND incident.status = 'RESOLVED' THEN 'COMPLETED'
          WHEN assignment.ended_at IS NOT NULL THEN 'REASSIGNED'
          WHEN assignment.accepted_by IS NOT NULL THEN 'ACTIVE'
          ELSE 'WAITING'
        END AS assignment_state`,
        'incident.description AS description',
        'incident.status AS status',
        'incident.severity_level AS severity_level',
        'incident.priority_score AS priority_score',
        'incident.priority_level AS priority_level',
        'incident.report_count AS report_count',
        'incident.created_at AS incident_created_at',
        `(incident.created_at + (CASE incident.priority_level WHEN 'EMERGENCY' THEN INTERVAL '1 hour' WHEN 'HIGH' THEN INTERVAL '4 hours' WHEN 'MEDIUM' THEN INTERVAL '12 hours' ELSE INTERVAL '24 hours' END)) AS sla_deadline`,
        `(SELECT MAX(u.created_at) FROM incident_updates u WHERE u.incident_id=incident.id) AS last_progress_at`,
        `(SELECT COUNT(*)::int FROM incident_updates u WHERE u.incident_id=incident.id AND u.new_status='PENDING_VERIFICATION') AS verification_attempts`,
        `EXISTS(SELECT 1 FROM incident_updates u WHERE u.incident_id=incident.id AND u.old_status='PENDING_VERIFICATION' AND u.new_status='IN_PROGRESS' AND u.created_at=(SELECT MAX(u2.created_at) FROM incident_updates u2 WHERE u2.incident_id=incident.id)) AS rework_required`,
        `(SELECT u.progress_percent FROM incident_updates u WHERE u.incident_id=incident.id AND u.progress_percent IS NOT NULL ORDER BY u.created_at DESC LIMIT 1) AS progress_percent`,
        `(SELECT m.file_url FROM incident_media m
          WHERE m.incident_id = incident.id AND m.media_type = 'IMAGE'
          ORDER BY m.created_at ASC LIMIT 1) AS cover_url`,
        'ST_Y(incident.location::geometry) AS latitude',
        'ST_X(incident.location::geometry) AS longitude',
        'type.name AS incident_type_name',
        'department.name AS department_name',
        `(SELECT report.reported_address
          FROM incident_reports report
          WHERE report.incident_id = incident.id
            AND NULLIF(TRIM(report.reported_address), '') IS NOT NULL
          ORDER BY report.created_at ASC
          LIMIT 1) AS address`,
      ]);

    if (scope === 'queue') {
      query.andWhere('assignment.ended_at IS NULL')
        .andWhere('assignment.accepted_by IS NULL')
        .andWhere("incident.status = 'ASSIGNED'")
        .andWhere('(assignment.assigned_officer_id IS NULL OR assignment.assigned_officer_id = :userId)', { userId });
    } else if (scope === 'mine') {
      query.andWhere('assignment.ended_at IS NULL')
        .andWhere('assignment.accepted_by = :userId', { userId })
        .andWhere("incident.status IN ('ACCEPTED', 'IN_PROGRESS', 'PENDING_VERIFICATION')");
    } else if (scope === 'history') {
      query.andWhere('assignment.ended_at IS NOT NULL')
        .andWhere('(assignment.accepted_by = :userId OR assignment.rejected_by = :userId)', { userId });
    } else {
      query.andWhere('assignment.ended_at IS NULL')
        .andWhere("incident.status NOT IN ('RESOLVED', 'REJECTED', 'CANCELLED', 'PENDING_ASSIGNMENT')")
        .andWhere(`(assignment.accepted_by = :userId OR
          (assignment.accepted_by IS NULL AND (assignment.assigned_officer_id IS NULL OR assignment.assigned_officer_id = :userId)))`, { userId });
    }

    return query.orderBy('incident.priority_score', 'DESC', 'NULLS LAST')
      .addOrderBy('assignment.assigned_at', 'ASC')
      .getRawMany();
  }

  /**
   * Cán bộ ấn "Tiếp nhận" sự cố
   */
  async acceptAssignment(assignmentId: string, userId: string, departmentId: string) {
    return AppDataSource.transaction(async (manager) => {
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const incidentRepo = manager.getRepository(Incident);
      const updateRepo = manager.getRepository(IncidentUpdate);
      const assignment = await assignmentRepo.findOne({
        where: { id: assignmentId, ended_at: IsNull() },
        lock: { mode: 'pessimistic_write' },
      });
      if (!assignment) throw { statusCode: 404, message: 'Không tìm thấy phân công hoặc đã kết thúc' };
      if (assignment.department_id !== departmentId) {
        throw { statusCode: 403, message: 'Bạn không thuộc đơn vị được phân công' };
      }
      if (assignment.accepted_by) {
        throw { statusCode: 409, message: 'Sự cố này đã được tiếp nhận bởi người khác' };
      }
      if (assignment.assigned_officer_id && assignment.assigned_officer_id !== userId) {
        throw { statusCode: 403, message: 'Nhiệm vụ này được chỉ định cho cán bộ khác' };
      }

      assignment.accepted_by = userId;
      assignment.accepted_at = new Date();
      await assignmentRepo.save(assignment);

      const incident = await incidentRepo.findOne({
        where: { id: assignment.incident_id },
        lock: { mode: 'pessimistic_write' },
      });
      if (!incident) throw { statusCode: 404, message: 'Sự cố không còn tồn tại' };
      const oldStatus = incident.status;
      if (oldStatus !== 'ASSIGNED') {
        throw { statusCode: 409, message: `Không thể tiếp nhận sự cố ở trạng thái ${oldStatus}` };
      }
      incident.status = 'ACCEPTED';
      await incidentRepo.save(incident);
      await updateRepo.save(updateRepo.create({
        incident_id: incident.id,
        updated_by: userId,
        old_status: oldStatus,
        new_status: 'ACCEPTED',
        note: 'Cán bộ đã tiếp nhận xử lý',
      }));
      await new NotificationService().notifyReporters(incident.id,'ASSIGNMENT_ACCEPTED','Sự cố đã được tiếp nhận','Cán bộ xử lý đã tiếp nhận phản ánh của bạn.',manager);
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
        lock: { mode: 'pessimistic_write' },
      });
      if (!assignment) throw { statusCode: 404, message: 'Phân công không còn hiệu lực' };
      if (assignment.department_id !== departmentId) {
        throw { statusCode: 403, message: 'Bạn không thuộc đơn vị được phân công' };
      }
      if (assignment.accepted_by) {
        throw {
          statusCode: 409,
          message: 'Nhiệm vụ đã được tiếp nhận. Hãy dùng Báo cáo trở ngại để yêu cầu điều phối.',
        };
      }
      if (assignment.assigned_officer_id && assignment.assigned_officer_id !== userId) {
        throw { statusCode: 403, message: 'Bạn không phải cán bộ được chỉ định cho nhiệm vụ này' };
      }

      const incident = await incidentRepo.findOne({
        where: { id: assignment.incident_id },
        lock: { mode: 'pessimistic_write' },
      });
      if (!incident) throw { statusCode: 404, message: 'Sự cố không còn tồn tại' };
      if (incident.status !== 'ASSIGNED') {
        throw { statusCode: 409, message: `Không thể từ chối hồ sơ ở trạng thái ${incident.status}` };
      }

      const now = new Date();
      assignment.ended_at = now;
      assignment.rejected_by = userId;
      assignment.rejection_code = data.reason_code;
      assignment.rejection_reason = data.reason.trim();
      assignment.rejected_at = now;
      await assignmentRepo.save(assignment);

      const oldStatus = incident.status;
      incident.status = 'PENDING_ASSIGNMENT';
      incident.ai_suggested_department_id = null;
      incident.ai_suggested_officer_id = null;
      await incidentRepo.save(incident);
      await updateRepo.save(updateRepo.create({
        incident_id: incident.id,
        updated_by: userId,
        old_status: oldStatus,
        new_status: 'PENDING_ASSIGNMENT',
        note: `Đang điều phối lại. Lý do: ${data.reason.trim()}`,
        visibility: 'PUBLIC',
      }));

      const notifications = new NotificationService();
      await notifications.notifyReporters(
        incident.id,
        'ASSIGNMENT_REALLOCATION',
        'Hồ sơ đang được điều phối lại',
        `Đơn vị tiếp nhận chưa phù hợp. Hệ thống đang chuyển hồ sơ tới đơn vị khác. Lý do: ${data.reason.trim()}`,
        manager,
      );
      await notifications.notifyAdmins({
        eventKey: `assignment-rejected:${assignment.id}`, type: 'ASSIGNMENT_REJECTED',
        incidentId: incident.id, title: 'Nhiệm vụ cần điều phối lại',
        message: data.reason.trim(), actionPath: `/incidents/${incident.id}`,
        actionLabel: 'Phân công lại',
        data: { assignment_id: assignment.id, reason_code: data.reason_code },
      }, manager);
      await new AuditLogService().record({
        user_id: userId,
        action: 'ASSIGNMENT_REJECTED',
        entity_type: 'incident_assignment',
        entity_id: assignment.id,
        details: {
          incident_id: incident.id,
          department_id: departmentId,
          reason_code: data.reason_code,
          reason: data.reason.trim(),
        },
      }, manager);
      return { assignment_id: assignment.id, incident_id: incident.id, status: incident.status };
    });
  }

  /**
   * Admin phân công lại thủ công
   */
  async reassign(data: any, adminId: string) {
    const { incident_id, new_department_id, reason } = data;
    return AppDataSource.transaction(async (manager) => {
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const incidentRepo = manager.getRepository(Incident);
      const updateRepo = manager.getRepository(IncidentUpdate);
      const incident = await incidentRepo.findOne({
        where: { id: incident_id },
        lock: { mode: 'pessimistic_write' },
      });
      if (!incident) throw { statusCode: 404, message: 'Không tìm thấy sự cố' };
      if (['RESOLVED', 'REJECTED', 'CANCELLED'].includes(incident.status)) {
        throw { statusCode: 409, message: 'Không thể phân công hồ sơ đã kết thúc' };
      }

      const departmentExists = await manager.query(
        'SELECT 1 FROM departments WHERE id = $1 AND is_active = TRUE',
        [new_department_id],
      );
      if (!departmentExists.length) throw { statusCode: 400, message: 'Đơn vị mới không tồn tại hoặc đã ngừng hoạt động' };

      const oldAssignment = await assignmentRepo.findOne({
        where: { incident_id, ended_at: IsNull() },
        lock: { mode: 'pessimistic_write' },
      });
      if (oldAssignment) {
        oldAssignment.ended_at = new Date();
        await assignmentRepo.save(oldAssignment);
      }

      const newAssignment = await assignmentRepo.save(assignmentRepo.create({
        incident_id,
        department_id: new_department_id,
        assigned_by: adminId,
        assignment_method: 'MANUAL',
        reason,
        assigned_at: new Date(),
      }));
      const oldStatus = incident.status;
      incident.status = 'ASSIGNED';
      incident.resolved_at = null;
      await incidentRepo.save(incident);
      await updateRepo.save(updateRepo.create({
        incident_id,
        updated_by: adminId,
        old_status: oldStatus,
        new_status: 'ASSIGNED',
        note: `Admin reassign: ${reason}`,
      }));
      await new AuditLogService().record({user_id:adminId,action:'INCIDENT_REASSIGNED',entity_type:'incident',entity_id:incident_id,details:{old_department_id:oldAssignment?.department_id,new_department_id,reason}},manager);
      await new NotificationService().notifyDepartment(incident_id,new_department_id,manager,newAssignment.id);
      return newAssignment;
    });
  }

  /**
   * Admin duyệt đề xuất phân công của AI (1-click approve)
   */
  async approveAiSuggestion(incidentId: string, adminId: string) {
    return AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const updateRepo = manager.getRepository(IncidentUpdate);

      const incident = await incidentRepo.findOne({
        where: { id: incidentId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!incident) throw { statusCode: 404, message: 'Không tìm thấy sự cố' };
      if (['RESOLVED', 'REJECTED', 'CANCELLED'].includes(incident.status)) {
        throw { statusCode: 409, message: 'Không thể phân công hồ sơ đã kết thúc' };
      }

      let deptId = incident.ai_suggested_department_id;
      let officerId = incident.ai_suggested_officer_id;
      let reason = incident.ai_suggestion_reason || 'Admin duyệt phân công theo đề xuất tự động của AI';

      // Nếu chưa có gợi ý trên incident (ví dụ sự cố cũ), tính ngay gợi ý
      if (!deptId || !officerId) {
        const suggestion = await new DepartmentAssignmentService().suggestOfficerAssignment(
          (incident.location as any).coordinates[0],
          (incident.location as any).coordinates[1],
          incident.incident_type_id,
          manager,
          incident.description,
        );
        if (!suggestion) {
          throw { statusCode: 400, message: 'Hệ thống không tìm thấy cán bộ/đơn vị phù hợp để phân công tự động' };
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
        lock: { mode: 'pessimistic_write' },
      });
      if (oldAssignment) {
        oldAssignment.ended_at = new Date();
        await assignmentRepo.save(oldAssignment);
      }

      // Tạo phân công mới với cán bộ được AI gợi ý
      const newAssignment = await assignmentRepo.save(assignmentRepo.create({
        incident_id: incidentId,
        department_id: deptId,
        assigned_officer_id: officerId,
        accepted_by: null,
        assigned_by: adminId,
        assignment_method: 'AI_SUGGESTED',
        reason,
        assigned_at: new Date(),
        accepted_at: null,
      }));

      const oldStatus = incident.status;
      incident.status = 'ASSIGNED';
      incident.resolved_at = null;
      await incidentRepo.save(incident);

      await updateRepo.save(updateRepo.create({
        incident_id: incidentId,
        updated_by: adminId,
        old_status: oldStatus,
        new_status: 'ASSIGNED',
        note: `Admin duyệt phân công đề xuất của AI: ${reason}`,
      }));

      await new AuditLogService().record({
        user_id: adminId,
        action: 'AI_ASSIGNMENT_APPROVED',
        entity_type: 'incident',
        entity_id: incidentId,
        details: { department_id: deptId, officer_id: officerId, reason }
      }, manager);

      // Thông báo cho đơn vị và người dân
      await new NotificationService().notifyDepartment(incidentId, deptId, manager, newAssignment.id, officerId);
      await new NotificationService().notifyReporters(
        incidentId,
        'ASSIGNMENT_CREATED',
        'Sự cố đã được phân công xử lý',
        `Sự cố của bạn đã được quản trị viên duyệt phân công cho cán bộ phụ trách tiếp nhận hiện trường.`,
        manager
      );

      return newAssignment;
    });
  }

  /**
   * Admin chủ động phân công cán bộ / đơn vị hoặc thay đổi theo ý muốn
   */
  async assignOfficer(data: { incident_id: string; department_id: string; officer_id?: string; reason?: string }, adminId: string) {
    const { incident_id, department_id, officer_id, reason } = data;
    return AppDataSource.transaction(async (manager) => {
      const incidentRepo = manager.getRepository(Incident);
      const assignmentRepo = manager.getRepository(IncidentAssignment);
      const updateRepo = manager.getRepository(IncidentUpdate);

      const incident = await incidentRepo.findOne({
        where: { id: incident_id },
        lock: { mode: 'pessimistic_write' },
      });
      if (!incident) throw { statusCode: 404, message: 'Không tìm thấy sự cố' };
      if (['RESOLVED', 'REJECTED', 'CANCELLED'].includes(incident.status)) {
        throw { statusCode: 409, message: 'Không thể phân công hồ sơ đã kết thúc' };
      }

      const oldAssignment = await assignmentRepo.findOne({
        where: { incident_id, ended_at: IsNull() },
        lock: { mode: 'pessimistic_write' },
      });
      if (oldAssignment) {
        oldAssignment.ended_at = new Date();
        await assignmentRepo.save(oldAssignment);
      }

      const noteText = reason?.trim() || (officer_id ? 'Admin phân công cán bộ xử lý' : 'Admin phân công đơn vị xử lý');

      const newAssignment = await assignmentRepo.save(assignmentRepo.create({
        incident_id,
        department_id,
        assigned_officer_id: officer_id || null,
        accepted_by: null,
        assigned_by: adminId,
        assignment_method: 'MANUAL',
        reason: noteText,
        assigned_at: new Date(),
        accepted_at: null,
      }));

      const oldStatus = incident.status;
      incident.status = 'ASSIGNED';
      incident.resolved_at = null;
      await incidentRepo.save(incident);

      await updateRepo.save(updateRepo.create({
        incident_id,
        updated_by: adminId,
        old_status: oldStatus,
        new_status: 'ASSIGNED',
        note: noteText,
      }));

      await new AuditLogService().record({
        user_id: adminId,
        action: 'INCIDENT_OFFICER_ASSIGNED',
        entity_type: 'incident',
        entity_id: incident_id,
        details: { department_id, officer_id, reason: noteText }
      }, manager);

      await new NotificationService().notifyDepartment(incident_id, department_id, manager, newAssignment.id, officer_id);
      await new NotificationService().notifyReporters(
        incident_id,
        'ASSIGNMENT_CREATED',
        'Sự cố đã được phân công xử lý',
        `Sự cố của bạn đã được phân công cho đơn vị phụ trách tiếp nhận hiện trường.`,
        manager
      );

      return newAssignment;
    });
  }

  /**
   * Lấy danh sách đề xuất AI & tất cả cán bộ ứng viên để Admin lựa chọn
   */
  async getCandidates(incidentId: string) {
    const incident = await this.incidentRepo.findOne({
      where: { id: incidentId },
      relations: { incident_type: true },
    });
    if (!incident) throw { statusCode: 404, message: 'Không tìm thấy sự cố' };

    const coords = (incident.location as any).coordinates;
    const suggestion = await new DepartmentAssignmentService().suggestOfficerAssignment(
      coords[0],
      coords[1],
      incident.incident_type_id,
      AppDataSource.manager,
      incident.description,
    );

    const departments = await AppDataSource.query(`
      SELECT d.id, d.code, d.name, d.address, d.phone,
        COALESCE(ST_Distance(d.location, ST_SetSRID(ST_Point($1, $2), 4326)::geography), 99999)::int AS distance_m
      FROM departments d
      WHERE d.is_active = TRUE
      ORDER BY distance_m ASC
    `, [coords[0], coords[1]]);

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

