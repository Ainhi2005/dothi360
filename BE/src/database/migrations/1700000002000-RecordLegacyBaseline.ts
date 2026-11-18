import { MigrationInterface, QueryRunner } from 'typeorm';

export class RecordLegacyBaseline1700000002000 implements MigrationInterface {
  name = 'RecordLegacyBaseline1700000002000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS migration_baseline_metadata (
        migration_name VARCHAR(255) PRIMARY KEY,
        was_existing BOOLEAN NOT NULL
      );
      INSERT INTO migration_baseline_metadata (migration_name, was_existing)
      VALUES ('InitialSchema1700000000000', TRUE)
      ON CONFLICT (migration_name) DO NOTHING;
    `);
  }

  public async down(_queryRunner: QueryRunner): Promise<void> {
    // Metadata thuộc migration initial và được xử lý khi revert initial.
  }
}
