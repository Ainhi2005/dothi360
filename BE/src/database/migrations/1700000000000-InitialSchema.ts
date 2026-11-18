import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialSchema1700000000000 implements MigrationInterface {
  name = 'InitialSchema1700000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    const [{ exists }] = await queryRunner.query(
      "SELECT to_regclass('public.departments') IS NOT NULL AS exists",
    );
    // Database cũ đã được tạo từ schema.sql: đánh dấu baseline, không tạo lại bảng.
    if (exists) {
      await queryRunner.query(`
        CREATE TABLE IF NOT EXISTS migration_baseline_metadata (
          migration_name VARCHAR(255) PRIMARY KEY,
          was_existing BOOLEAN NOT NULL
        );
        INSERT INTO migration_baseline_metadata (migration_name, was_existing)
        VALUES ('InitialSchema1700000000000', TRUE)
        ON CONFLICT (migration_name) DO NOTHING;
      `);
      return;
    }

    const candidates = [
      resolve(__dirname, '..', 'schema.sql'),
      resolve(process.cwd(), 'src', 'database', 'schema.sql'),
      resolve(process.cwd(), 'dist', 'database', 'schema.sql'),
    ];
    const schemaPath = candidates.find((candidate) => {
      try {
        readFileSync(candidate);
        return true;
      } catch {
        return false;
      }
    });
    if (!schemaPath) throw new Error('Không tìm thấy src/database/schema.sql');

    const sql = readFileSync(schemaPath, 'utf8')
      .replace(/^\s*BEGIN;\s*/i, '')
      .replace(/\s*COMMIT;\s*(?:--[\s\S]*)?$/i, '');
    await queryRunner.query(sql);
    await queryRunner.query(`
      CREATE TABLE migration_baseline_metadata (
        migration_name VARCHAR(255) PRIMARY KEY,
        was_existing BOOLEAN NOT NULL
      );
      INSERT INTO migration_baseline_metadata (migration_name, was_existing)
      VALUES ('InitialSchema1700000000000', FALSE);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    const metadataTableExists = await queryRunner.hasTable('migration_baseline_metadata');
    if (metadataTableExists) {
      const rows = await queryRunner.query(
        "SELECT was_existing FROM migration_baseline_metadata WHERE migration_name = 'InitialSchema1700000000000'",
      );
      if (rows[0]?.was_existing) {
        await queryRunner.query("DELETE FROM migration_baseline_metadata WHERE migration_name = 'InitialSchema1700000000000'");
        return;
      }
    }
    await queryRunner.query(`
      DROP TABLE IF EXISTS audit_logs CASCADE;
      DROP TABLE IF EXISTS algorithm_configs CASCADE;
      DROP TABLE IF EXISTS ratings CASCADE;
      DROP TABLE IF EXISTS notifications CASCADE;
      DROP TABLE IF EXISTS incident_assignments CASCADE;
      DROP TABLE IF EXISTS incident_media CASCADE;
      DROP TABLE IF EXISTS incident_updates CASCADE;
      DROP TABLE IF EXISTS incident_reports CASCADE;
      DROP TABLE IF EXISTS incidents CASCADE;
      DROP TABLE IF EXISTS department_incident_types CASCADE;
      DROP TABLE IF EXISTS incident_types CASCADE;
      DROP TABLE IF EXISTS areas CASCADE;
      DROP TABLE IF EXISTS device_tokens CASCADE;
      DROP TABLE IF EXISTS refresh_tokens CASCADE;
      DROP TABLE IF EXISTS users CASCADE;
      DROP TABLE IF EXISTS departments CASCADE;
      DROP FUNCTION IF EXISTS set_updated_at();
      DROP TABLE IF EXISTS migration_baseline_metadata;
    `);
  }
}
