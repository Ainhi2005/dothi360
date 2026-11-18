import { AppDataSource } from '../database/data-source';
import { Incident } from '../modules/incidents/incident.entity';
import { PriorityScoringService } from '../algorithms/priority-scoring/priority-scoring.service';

export async function recalculateOpenIncidentPriorities() {
  const runner = AppDataSource.createQueryRunner();
  await runner.connect();
  try {
    const [{ locked }] = await runner.query("SELECT pg_try_advisory_lock(hashtext('job:recalculate-priority')) locked");
    if (!locked) return 0;
    const rows = await runner.manager.getRepository(Incident).createQueryBuilder('incident').leftJoinAndSelect('incident.incident_type', 'type').where("incident.status NOT IN ('RESOLVED','REJECTED','CANCELLED')").getMany();
    const scoring = new PriorityScoringService();
    for (const incident of rows) {
      const previousLevel = incident.priority_level;
      const result = await scoring.calculateConfigured(incident.incident_type.type_priority_level, incident.severity_level, incident.report_count, incident.created_at, runner.manager);
      incident.priority_score = result.score;
      incident.priority_level = result.level;
      if (!['HIGH','EMERGENCY'].includes(previousLevel ?? '') && ['HIGH','EMERGENCY'].includes(result.level)) {
        await runner.query(`INSERT INTO notifications(user_id,incident_id,type,title,message,data)
          SELECT a.accepted_by,$1,'PRIORITY_ESCALATED','Mức ưu tiên vừa tăng',$2,
            jsonb_build_object('incident_id',$1::uuid,'assignment_id',a.id,'priority_level',$3::text)
          FROM incident_assignments a WHERE a.incident_id=$1 AND a.ended_at IS NULL AND a.accepted_by IS NOT NULL`,
          [incident.id,`${incident.incident_type.name} đã chuyển sang mức ${result.level}.`,result.level]);
      }
    }
    if (rows.length) await runner.manager.getRepository(Incident).save(rows);
    return rows.length;
  } finally {
    try { await runner.query("SELECT pg_advisory_unlock(hashtext('job:recalculate-priority'))"); } catch (_) {}
    await runner.release();
  }
}
