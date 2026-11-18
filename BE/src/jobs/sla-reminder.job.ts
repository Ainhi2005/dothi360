import { NotificationService } from '../modules/notifications/notification.service';
import { AppDataSource } from '../database/data-source';

export async function createSlaReminders() {
  const runner = AppDataSource.createQueryRunner();
  await runner.connect();
  try {
    const [{ locked }] = await runner.query("SELECT pg_try_advisory_lock(hashtext('job:sla-reminders')) locked");
    if (!locked) return 0;
    const result = await runner.query(`
      INSERT INTO notifications(user_id,incident_id,type,title,message,data)
      SELECT a.accepted_by,i.id,
        CASE WHEN NOW() >= deadline.sla_at THEN 'SLA_OVERDUE' ELSE 'SLA_DUE_SOON' END,
        CASE WHEN NOW() >= deadline.sla_at THEN 'Nhiệm vụ đã quá SLA' ELSE 'Nhiệm vụ sắp đến hạn SLA' END,
        CONCAT(t.name,' · hạn xử lý ',TO_CHAR(deadline.sla_at AT TIME ZONE 'Asia/Ho_Chi_Minh','DD/MM HH24:MI')),
        jsonb_build_object('incident_id',i.id,'assignment_id',a.id,'sla_deadline',deadline.sla_at)
      FROM incidents i
      JOIN incident_assignments a ON a.incident_id=i.id AND a.ended_at IS NULL AND a.accepted_by IS NOT NULL
      JOIN incident_types t ON t.id=i.incident_type_id
      CROSS JOIN LATERAL (SELECT (i.created_at + CASE i.priority_level
        WHEN 'EMERGENCY' THEN INTERVAL '1 hour' WHEN 'HIGH' THEN INTERVAL '4 hours'
        WHEN 'MEDIUM' THEN INTERVAL '12 hours' ELSE INTERVAL '24 hours' END) sla_at) deadline
      WHERE i.status IN('ACCEPTED','IN_PROGRESS')
        AND NOW() >= deadline.sla_at - INTERVAL '30 minutes'
        AND NOT EXISTS(SELECT 1 FROM notifications n WHERE n.user_id=a.accepted_by AND n.incident_id=i.id
          AND n.type=CASE WHEN NOW() >= deadline.sla_at THEN 'SLA_OVERDUE' ELSE 'SLA_DUE_SOON' END
          AND n.created_at > NOW()-INTERVAL '24 hours')
      RETURNING id
    `);
    const overdue = await runner.query(`
      SELECT i.id,a.id assignment_id,t.name FROM incidents i
      JOIN incident_assignments a ON a.incident_id=i.id AND a.ended_at IS NULL AND a.accepted_by IS NOT NULL
      JOIN incident_types t ON t.id=i.incident_type_id
      WHERE i.status IN ('ACCEPTED','IN_PROGRESS') AND NOW() >= i.created_at + CASE i.priority_level
        WHEN 'EMERGENCY' THEN INTERVAL '1 hour' WHEN 'HIGH' THEN INTERVAL '4 hours'
        WHEN 'MEDIUM' THEN INTERVAL '12 hours' ELSE INTERVAL '24 hours' END
    `);
    let adminCount = 0;
    for (const item of overdue) {
      const created = await new NotificationService().notifyAdmins({
        eventKey: `sla-overdue:${item.assignment_id}:${new Date().toISOString().slice(0,10)}`,
        type: 'INCIDENT_SLA_OVERDUE', incidentId: item.id, title: 'Hồ sơ đã quá hạn xử lý',
        message: `${item.name}: cần kiểm tra tiến độ và điều phối xử lý.`,
        actionPath: `/incidents/${item.id}`, actionLabel: 'Kiểm tra tiến độ',
        data: { assignment_id: item.assignment_id },
      }, runner.manager);
      adminCount += created.length;
    }
    return result.length + adminCount;
  } finally {
    try { await runner.query("SELECT pg_advisory_unlock(hashtext('job:sla-reminders'))"); } catch (_) {}
    await runner.release();
  }
}
