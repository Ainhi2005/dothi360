import { MigrationInterface, QueryRunner } from 'typeorm';

export class RetireCoordinationChecklist1700000018000 implements MigrationInterface {
  name = 'RetireCoordinationChecklist1700000018000';

  async up(queryRunner: QueryRunner): Promise<void> {
    // Keep historical checklist results while removing this retired requirement.
    await queryRunner.query(`
      UPDATE incident_type_checklist_items
      SET is_active = FALSE, is_required = FALSE
      WHERE title = 'Đã phối hợp đơn vị liên quan khi cần';
    `);
  }

  async down(): Promise<void> {
    // Previous active/required values cannot be safely inferred. Templates can
    // be restored explicitly by an administrator if the feature returns.
  }
}
