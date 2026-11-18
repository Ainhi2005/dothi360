import { MigrationInterface, QueryRunner } from 'typeorm';

export class RepairAutoAcceptedAssignments1700000017000 implements MigrationInterface {
  name = 'RepairAutoAcceptedAssignments1700000017000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE incident_assignments assignment
      SET assigned_officer_id = COALESCE(assignment.assigned_officer_id, assignment.accepted_by),
          accepted_by = NULL,
          accepted_at = NULL
      FROM incidents incident
      WHERE incident.id = assignment.incident_id
        AND assignment.ended_at IS NULL
        AND incident.status = 'ASSIGNED'
        AND assignment.accepted_by IS NOT NULL;
    `);
  }

  async down(): Promise<void> {
    // Không thể suy ra an toàn cán bộ nào đã thật sự bấm tiếp nhận trong dữ liệu cũ.
  }
}
