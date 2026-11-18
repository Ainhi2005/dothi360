import { MigrationInterface, QueryRunner } from 'typeorm';

export class ProgressTracking1700000010000 implements MigrationInterface {
  name = 'ProgressTracking1700000010000';
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE incident_updates
        ADD COLUMN progress_percent SMALLINT,
        ADD COLUMN estimated_completion_at TIMESTAMPTZ,
        ADD COLUMN blocker TEXT,
        ADD COLUMN visibility VARCHAR(20) NOT NULL DEFAULT 'PUBLIC';
      ALTER TABLE incident_updates ADD CONSTRAINT ck_update_progress
        CHECK(progress_percent IS NULL OR progress_percent BETWEEN 0 AND 100);
      ALTER TABLE incident_updates ADD CONSTRAINT ck_update_visibility
        CHECK(visibility IN ('PUBLIC','INTERNAL'));
      CREATE INDEX idx_incident_updates_progress ON incident_updates(incident_id,created_at DESC);
    `);
  }
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS idx_incident_updates_progress;
      ALTER TABLE incident_updates DROP CONSTRAINT IF EXISTS ck_update_visibility;
      ALTER TABLE incident_updates DROP CONSTRAINT IF EXISTS ck_update_progress;
      ALTER TABLE incident_updates DROP COLUMN IF EXISTS visibility;
      ALTER TABLE incident_updates DROP COLUMN IF EXISTS blocker;
      ALTER TABLE incident_updates DROP COLUMN IF EXISTS estimated_completion_at;
      ALTER TABLE incident_updates DROP COLUMN IF EXISTS progress_percent;`);
  }
}
