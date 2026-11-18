import { MigrationInterface, QueryRunner } from 'typeorm';

export class AiDecisionSupport1700000005000 implements MigrationInterface {
  name = 'AiDecisionSupport1700000005000';
  async up(q: QueryRunner) {
    await q.query(`
      ALTER TABLE incident_reports ADD COLUMN IF NOT EXISTS duplicate_score NUMERIC(5,4);
      ALTER TABLE incident_reports ADD COLUMN IF NOT EXISTS duplicate_evidence JSONB;
      CREATE TABLE IF NOT EXISTS ai_feedbacks (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        report_id UUID NOT NULL REFERENCES incident_reports(id) ON DELETE CASCADE,
        actor_id UUID REFERENCES users(id) ON DELETE SET NULL,
        source VARCHAR(30) NOT NULL CHECK (source IN ('CITIZEN_CONFIRMATION','ADMIN_REVIEW')),
        ai_incident_type VARCHAR(200), confirmed_incident_type_id UUID REFERENCES incident_types(id),
        ai_severity SMALLINT, confirmed_severity SMALLINT,
        decision VARCHAR(30) NOT NULL, note TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
      CREATE INDEX IF NOT EXISTS idx_ai_feedbacks_report ON ai_feedbacks(report_id,created_at DESC);
    `);
  }
  async down(q: QueryRunner) {
    await q.query(`DROP TABLE IF EXISTS ai_feedbacks; ALTER TABLE incident_reports DROP COLUMN IF EXISTS duplicate_evidence; ALTER TABLE incident_reports DROP COLUMN IF EXISTS duplicate_score;`);
  }
}
