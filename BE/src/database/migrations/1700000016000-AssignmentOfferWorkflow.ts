import { MigrationInterface, QueryRunner } from 'typeorm';

export class AssignmentOfferWorkflow1700000016000 implements MigrationInterface {
  name = 'AssignmentOfferWorkflow1700000016000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE incident_assignments
        ADD COLUMN assigned_officer_id UUID REFERENCES users(id);

      UPDATE incident_assignments
      SET assigned_officer_id = accepted_by
      WHERE accepted_by IS NOT NULL;

      CREATE INDEX idx_assignments_offered_officer
        ON incident_assignments(assigned_officer_id, assigned_at DESC)
        WHERE ended_at IS NULL AND accepted_by IS NULL;
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS idx_assignments_offered_officer;
      ALTER TABLE incident_assignments DROP COLUMN IF EXISTS assigned_officer_id;
    `);
  }
}
