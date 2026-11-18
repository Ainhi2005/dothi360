import { MigrationInterface, QueryRunner } from 'typeorm';

export class AssignmentRejectionAndReportLocation1700000014000 implements MigrationInterface {
  name = 'AssignmentRejectionAndReportLocation1700000014000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE incident_assignments
        ADD COLUMN rejected_by UUID REFERENCES users(id),
        ADD COLUMN rejection_code VARCHAR(40),
        ADD COLUMN rejection_reason TEXT,
        ADD COLUMN rejected_at TIMESTAMPTZ;
      ALTER TABLE incident_reports
        ADD COLUMN reported_address TEXT,
        ADD COLUMN location_source VARCHAR(20) NOT NULL DEFAULT 'GPS',
        ADD CONSTRAINT ck_report_location_source CHECK (location_source IN ('GPS','MAP','SEARCH'));
      CREATE INDEX idx_assignments_rejected_at ON incident_assignments(rejected_at DESC)
        WHERE rejected_at IS NOT NULL;
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS idx_assignments_rejected_at;
      ALTER TABLE incident_reports DROP CONSTRAINT IF EXISTS ck_report_location_source;
      ALTER TABLE incident_reports DROP COLUMN IF EXISTS location_source, DROP COLUMN IF EXISTS reported_address;
      ALTER TABLE incident_assignments DROP COLUMN IF EXISTS rejected_at, DROP COLUMN IF EXISTS rejection_reason,
        DROP COLUMN IF EXISTS rejection_code, DROP COLUMN IF EXISTS rejected_by;
    `);
  }
}
