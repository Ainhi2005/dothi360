import { MigrationInterface, QueryRunner } from 'typeorm';

export class OfficerP21700000013000 implements MigrationInterface {
  name = 'OfficerP21700000013000';
  async up(q: QueryRunner) { await q.query(`
    CREATE TABLE shift_handovers(id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),from_officer_id UUID NOT NULL REFERENCES users(id),to_officer_id UUID REFERENCES users(id),department_id UUID NOT NULL REFERENCES departments(id),note TEXT NOT NULL,status VARCHAR(20) NOT NULL DEFAULT 'PENDING',created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),accepted_at TIMESTAMPTZ,CONSTRAINT ck_handover_status CHECK(status IN('PENDING','ACCEPTED','CANCELLED')));
    CREATE TABLE shift_handover_items(id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),handover_id UUID NOT NULL REFERENCES shift_handovers(id) ON DELETE CASCADE,incident_id UUID NOT NULL REFERENCES incidents(id),latest_progress TEXT,is_urgent BOOLEAN NOT NULL DEFAULT FALSE,UNIQUE(handover_id,incident_id));
    CREATE TABLE task_messages(id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),incident_id UUID NOT NULL REFERENCES incidents(id),sender_id UUID NOT NULL REFERENCES users(id),message TEXT NOT NULL,media_url TEXT,location JSONB,is_internal BOOLEAN NOT NULL DEFAULT TRUE,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
    CREATE TABLE ai_officer_assistance(id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),incident_id UUID NOT NULL REFERENCES incidents(id),requested_by UUID NOT NULL REFERENCES users(id),result JSONB NOT NULL,model VARCHAR(100),created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
    CREATE INDEX idx_handover_department ON shift_handovers(department_id,status,created_at DESC);
    CREATE INDEX idx_task_messages_incident ON task_messages(incident_id,created_at);
    CREATE INDEX idx_ai_assistance_incident ON ai_officer_assistance(incident_id,created_at DESC);
  `); }
  async down(q: QueryRunner) { await q.query('DROP TABLE IF EXISTS ai_officer_assistance;DROP TABLE IF EXISTS task_messages;DROP TABLE IF EXISTS shift_handover_items;DROP TABLE IF EXISTS shift_handovers;'); }
}
