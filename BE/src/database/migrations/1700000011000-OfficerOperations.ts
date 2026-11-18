import { MigrationInterface, QueryRunner } from 'typeorm';
export class OfficerOperations1700000011000 implements MigrationInterface {
  name='OfficerOperations1700000011000';
  async up(q:QueryRunner){await q.query(`
    ALTER TABLE incidents ADD COLUMN IF NOT EXISTS sla_deadline_override TIMESTAMPTZ;
    CREATE TABLE incident_type_checklist_items(id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),incident_type_id UUID NOT NULL REFERENCES incident_types(id),title VARCHAR(250) NOT NULL,description TEXT,is_required BOOLEAN NOT NULL DEFAULT TRUE,sort_order INT NOT NULL DEFAULT 0,is_active BOOLEAN NOT NULL DEFAULT TRUE,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
    CREATE TABLE incident_checklist_results(id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),incident_id UUID NOT NULL REFERENCES incidents(id),checklist_item_id UUID NOT NULL REFERENCES incident_type_checklist_items(id),completed BOOLEAN NOT NULL DEFAULT FALSE,note TEXT,completed_by UUID REFERENCES users(id),completed_at TIMESTAMPTZ,updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),UNIQUE(incident_id,checklist_item_id));
    CREATE TABLE coordination_requests(id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),incident_id UUID NOT NULL REFERENCES incidents(id),requesting_department_id UUID NOT NULL REFERENCES departments(id),target_department_id UUID NOT NULL REFERENCES departments(id),requested_by UUID NOT NULL REFERENCES users(id),content TEXT NOT NULL,urgency VARCHAR(20) NOT NULL DEFAULT 'NORMAL',status VARCHAR(20) NOT NULL DEFAULT 'PENDING',response_note TEXT,responded_by UUID REFERENCES users(id),responded_at TIMESTAMPTZ,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),CONSTRAINT ck_coord_urgency CHECK(urgency IN('NORMAL','HIGH','EMERGENCY')),CONSTRAINT ck_coord_status CHECK(status IN('PENDING','ACCEPTED','DECLINED','COMPLETED')));
    CREATE TABLE incident_obstacles(id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),incident_id UUID NOT NULL REFERENCES incidents(id),reported_by UUID NOT NULL REFERENCES users(id),type VARCHAR(40) NOT NULL,description TEXT NOT NULL,requested_extension_hours INT,status VARCHAR(20) NOT NULL DEFAULT 'PENDING',admin_note TEXT,resolved_by UUID REFERENCES users(id),resolved_at TIMESTAMPTZ,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),CONSTRAINT ck_obstacle_status CHECK(status IN('PENDING','APPROVED','REJECTED','RESOLVED')));
    CREATE INDEX idx_checklist_type ON incident_type_checklist_items(incident_type_id,is_active,sort_order);
    CREATE INDEX idx_coord_incident ON coordination_requests(incident_id,created_at DESC);
    CREATE INDEX idx_obstacle_incident ON incident_obstacles(incident_id,created_at DESC);
  `)}
  async down(q:QueryRunner){await q.query('DROP TABLE IF EXISTS incident_obstacles;DROP TABLE IF EXISTS coordination_requests;DROP TABLE IF EXISTS incident_checklist_results;DROP TABLE IF EXISTS incident_type_checklist_items;ALTER TABLE incidents DROP COLUMN IF EXISTS sla_deadline_override;')}
}
