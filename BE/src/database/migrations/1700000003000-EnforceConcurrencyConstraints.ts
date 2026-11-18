import { MigrationInterface, QueryRunner } from 'typeorm';

export class EnforceConcurrencyConstraints1700000003000 implements MigrationInterface {
  name = 'EnforceConcurrencyConstraints1700000003000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS uq_incident_assignments_current
      ON incident_assignments (incident_id)
      WHERE ended_at IS NULL;

      CREATE UNIQUE INDEX IF NOT EXISTS uq_incident_reports_incident_reporter
      ON incident_reports (incident_id, reporter_id);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP INDEX IF EXISTS uq_incident_assignments_current');
    // Không xóa uniqueness của report vì đây là invariant dữ liệu trong initial schema.
  }
}
