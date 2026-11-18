import { AppDataSource } from '../../database/data-source';
import { AuditLogService } from '../audit-logs/audit-log.service';

export class OfficerOperationService {
  private audit = new AuditLogService();

  private async assertOfficerIncident(incidentId: string, userId: string, departmentId: string) {
    const rows = await AppDataSource.query(
      `SELECT i.id, i.incident_type_id 
       FROM incidents i 
       JOIN incident_assignments a ON a.incident_id = i.id AND a.ended_at IS NULL 
       WHERE i.id = $1 AND a.department_id = $2 AND (a.accepted_by IS NULL OR a.accepted_by = $3)`,
      [incidentId, departmentId, userId]
    );
    if (!rows.length) throw { statusCode: 403, message: 'Nhiệm vụ không thuộc phạm vi của bạn' };
    return rows[0];
  }

  async checklist(incidentId: string, userId: string, departmentId: string) {
    const incident = await this.assertOfficerIncident(incidentId, userId, departmentId);
    return AppDataSource.query(
      `SELECT c.id, c.title, c.description, c.is_required, c.sort_order, 
              COALESCE(r.completed, FALSE) AS completed, r.note, r.completed_at 
       FROM incident_type_checklist_items c 
       LEFT JOIN incident_checklist_results r ON r.checklist_item_id = c.id AND r.incident_id = $1 
       WHERE c.incident_type_id = $2 AND c.is_active = TRUE 
       ORDER BY c.sort_order, c.created_at`,
      [incidentId, incident.incident_type_id]
    );
  }

  async saveChecklist(incidentId: string, userId: string, departmentId: string, items: any[]) {
    await this.assertOfficerIncident(incidentId, userId, departmentId);
    await AppDataSource.transaction(async (m) => {
      for (const item of items) {
        await m.query(
          `INSERT INTO incident_checklist_results(incident_id, checklist_item_id, completed, note, completed_by, completed_at) 
           SELECT $1, c.id, $3, $4, $5, CASE WHEN $3 THEN NOW() ELSE NULL END 
           FROM incident_type_checklist_items c 
           JOIN incidents i ON i.incident_type_id = c.incident_type_id 
           WHERE c.id = $2 AND i.id = $1 AND c.is_active = TRUE 
           ON CONFLICT(incident_id, checklist_item_id) 
           DO UPDATE SET completed = $3, note = $4, completed_by = $5, 
                         completed_at = CASE WHEN $3 THEN NOW() ELSE NULL END, updated_at = NOW()`,
          [incidentId, item.id, item.completed, item.note ?? null, userId]
        );
      }
    });
    return this.checklist(incidentId, userId, departmentId);
  }

  templates(typeId: string) {
    return AppDataSource.query(
      'SELECT * FROM incident_type_checklist_items WHERE incident_type_id = $1 AND is_active = TRUE ORDER BY sort_order, created_at',
      [typeId]
    );
  }

  async replaceTemplates(typeId: string, items: any[]) {
    return AppDataSource.transaction(async (m) => {
      await m.query(
        'UPDATE incident_type_checklist_items SET is_active = FALSE WHERE incident_type_id = $1',
        [typeId]
      );
      for (let i = 0; i < items.length; i++) {
        await m.query(
          `INSERT INTO incident_type_checklist_items(incident_type_id, title, description, is_required, sort_order) 
           VALUES($1, $2, $3, $4, $5)`,
          [typeId, items[i].title, items[i].description ?? null, items[i].is_required ?? true, i]
        );
      }
      return this.templates(typeId);
    });
  }

  async performance(userId: string) {
    const [summary] = await AppDataSource.query(
      `SELECT COUNT(*)FILTER(WHERE a.ended_at IS NULL)::int AS active,
              COUNT(*)FILTER(WHERE a.ended_at IS NOT NULL)::int AS completed,
              COALESCE(ROUND(AVG(EXTRACT(EPOCH FROM(a.accepted_at - a.assigned_at))/60)FILTER(WHERE a.accepted_at IS NOT NULL), 1), 0)::float AS avg_accept_minutes,
              COUNT(*)FILTER(WHERE EXISTS(SELECT 1 FROM incident_updates u WHERE u.incident_id = a.incident_id AND u.old_status = 'PENDING_VERIFICATION' AND u.new_status = 'IN_PROGRESS'))::int AS reworked,
              COALESCE(ROUND(100.0 * COUNT(*)FILTER(WHERE a.ended_at IS NOT NULL AND COALESCE(i.resolved_at, NOW()) <= (i.created_at + CASE i.priority_level WHEN 'EMERGENCY' THEN INTERVAL '1 hour' WHEN 'HIGH' THEN INTERVAL '4 hours' WHEN 'MEDIUM' THEN INTERVAL '12 hours' ELSE INTERVAL '24 hours' END)) / NULLIF(COUNT(*)FILTER(WHERE a.ended_at IS NOT NULL), 0), 1), 100)::float AS sla_rate 
       FROM incident_assignments a 
       JOIN incidents i ON i.id = a.incident_id 
       WHERE a.accepted_by = $1`,
      [userId]
    );
    const trend = await AppDataSource.query(
      `SELECT date_trunc('week', COALESCE(i.resolved_at, a.assigned_at))::date AS period,
              COUNT(*)::int AS total,
              COUNT(*)FILTER(WHERE i.status = 'RESOLVED')::int AS completed 
       FROM incident_assignments a 
       JOIN incidents i ON i.id = a.incident_id 
       WHERE a.accepted_by = $1 AND a.assigned_at > NOW() - INTERVAL '12 weeks' 
       GROUP BY 1 
       ORDER BY 1`,
      [userId]
    );
    return { summary, trend };
  }
}
