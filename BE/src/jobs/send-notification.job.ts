import { AppDataSource } from '../database/data-source';
import { FirebaseService } from '../integrations/firebase/firebase.service';

export async function sendPendingNotifications() {
  const runner = AppDataSource.createQueryRunner();
  await runner.connect();
  const [{ locked }] = await runner.query("SELECT pg_try_advisory_lock(hashtext('job:send-notifications')) locked");
  if (!locked) { await runner.release(); return 0; }
  try {
  const rows = await runner.query(`SELECT n.*,COALESCE(array_agg(dt.token) FILTER(WHERE dt.token IS NOT NULL),'{}') tokens FROM notifications n LEFT JOIN device_tokens dt ON dt.user_id=n.user_id AND dt.is_active=TRUE WHERE n.push_status IN('PENDING','FAILED') AND n.push_attempts<3 GROUP BY n.id ORDER BY n.created_at LIMIT 100`);
  for (const notification of rows) {
    try {
      await runner.query("UPDATE notifications SET push_status='PROCESSING',push_attempts=push_attempts+1 WHERE id=$1", [notification.id]);
      if (!notification.tokens.length) {
        await runner.query("UPDATE notifications SET push_status='SKIPPED' WHERE id=$1", [notification.id]);
        continue;
      }
      const result = await new FirebaseService().send(notification.tokens, notification.title, notification.message, {
        incident_id: notification.incident_id ?? '',
        assignment_id: notification.data?.assignment_id ?? '',
        area_id: notification.data?.area_id ?? '',
        feedback_id: notification.data?.feedback_id ?? '',
        action: notification.data?.action ?? '',
        type: notification.type,
      });
      await runner.query("UPDATE notifications SET push_status=$2,push_sent_at=CASE WHEN $2='SENT' THEN NOW() END,push_last_error=$3 WHERE id=$1", [notification.id, result.successCount ? 'SENT' : 'FAILED', result.successCount ? null : 'Không gửi được tới thiết bị']);
    } catch (error) {
      await runner.query("UPDATE notifications SET push_status='FAILED',push_last_error=$2 WHERE id=$1", [notification.id, error instanceof Error ? error.message : String(error)]);
    }
  }
  return rows.length;
  } finally {
    try { await runner.query("SELECT pg_advisory_unlock(hashtext('job:send-notifications'))"); } catch (_) {}
    await runner.release();
  }
}
