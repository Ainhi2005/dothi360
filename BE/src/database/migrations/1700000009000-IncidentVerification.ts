import { MigrationInterface, QueryRunner } from 'typeorm';

export class IncidentVerification1700000009000 implements MigrationInterface {
  name = 'IncidentVerification1700000009000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE incidents DROP CONSTRAINT IF EXISTS ck_incidents_status;
      ALTER TABLE incidents ADD CONSTRAINT ck_incidents_status CHECK (status IN (
        'PENDING_ASSIGNMENT', 'ASSIGNED', 'ACCEPTED', 'IN_PROGRESS',
        'PENDING_VERIFICATION', 'RESOLVED', 'REJECTED', 'CANCELLED'
      ));
      ALTER TABLE incident_updates DROP CONSTRAINT IF EXISTS ck_incident_updates_old_status;
      ALTER TABLE incident_updates DROP CONSTRAINT IF EXISTS ck_incident_updates_new_status;
      ALTER TABLE incident_updates ADD CONSTRAINT ck_incident_updates_old_status CHECK (
        old_status IS NULL OR old_status IN (
          'PENDING_ASSIGNMENT', 'ASSIGNED', 'ACCEPTED', 'IN_PROGRESS',
          'PENDING_VERIFICATION', 'RESOLVED', 'REJECTED', 'CANCELLED'
        )
      );
      ALTER TABLE incident_updates ADD CONSTRAINT ck_incident_updates_new_status CHECK (
        new_status IS NULL OR new_status IN (
          'PENDING_ASSIGNMENT', 'ASSIGNED', 'ACCEPTED', 'IN_PROGRESS',
          'PENDING_VERIFICATION', 'RESOLVED', 'REJECTED', 'CANCELLED'
        )
      );
      CREATE INDEX IF NOT EXISTS idx_incidents_pending_verification
        ON incidents(updated_at ASC) WHERE status = 'PENDING_VERIFICATION';
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE incidents SET status = 'IN_PROGRESS' WHERE status = 'PENDING_VERIFICATION';
      UPDATE incident_updates SET old_status = 'IN_PROGRESS' WHERE old_status = 'PENDING_VERIFICATION';
      UPDATE incident_updates SET new_status = 'IN_PROGRESS' WHERE new_status = 'PENDING_VERIFICATION';
      DROP INDEX IF EXISTS idx_incidents_pending_verification;
      ALTER TABLE incidents DROP CONSTRAINT IF EXISTS ck_incidents_status;
      ALTER TABLE incidents ADD CONSTRAINT ck_incidents_status CHECK (status IN (
        'PENDING_ASSIGNMENT', 'ASSIGNED', 'ACCEPTED', 'IN_PROGRESS',
        'RESOLVED', 'REJECTED', 'CANCELLED'
      ));
      ALTER TABLE incident_updates DROP CONSTRAINT IF EXISTS ck_incident_updates_old_status;
      ALTER TABLE incident_updates DROP CONSTRAINT IF EXISTS ck_incident_updates_new_status;
      ALTER TABLE incident_updates ADD CONSTRAINT ck_incident_updates_old_status CHECK (
        old_status IS NULL OR old_status IN ('PENDING_ASSIGNMENT','ASSIGNED','ACCEPTED','IN_PROGRESS','RESOLVED','REJECTED','CANCELLED')
      );
      ALTER TABLE incident_updates ADD CONSTRAINT ck_incident_updates_new_status CHECK (
        new_status IS NULL OR new_status IN ('PENDING_ASSIGNMENT','ASSIGNED','ACCEPTED','IN_PROGRESS','RESOLVED','REJECTED','CANCELLED')
      );
    `);
  }
}
