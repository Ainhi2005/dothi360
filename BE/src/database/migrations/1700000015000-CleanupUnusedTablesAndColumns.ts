import { MigrationInterface, QueryRunner } from 'typeorm';

export class CleanupUnusedTablesAndColumns1700000015000 implements MigrationInterface {
  name = 'CleanupUnusedTablesAndColumns1700000015000';

  async up(q: QueryRunner): Promise<void> {
    // 1. Xóa các bảng phụ và bảng kỹ thuật thừa
    await q.query('DROP TABLE IF EXISTS shift_handover_items CASCADE;');
    await q.query('DROP TABLE IF EXISTS shift_handovers CASCADE;');
    await q.query('DROP TABLE IF EXISTS task_messages CASCADE;');
    await q.query('DROP TABLE IF EXISTS incident_obstacles CASCADE;');
    await q.query('DROP TABLE IF EXISTS ai_officer_assistance CASCADE;');
    await q.query('DROP TABLE IF EXISTS migration_baseline_metadata CASCADE;');

    // 2. Xóa cột thừa trong incident_media
    await q.query('ALTER TABLE incident_media DROP COLUMN IF EXISTS checksum;');

    // 3. Xóa cột sla_deadline_override thừa trong incidents
    await q.query('ALTER TABLE incidents DROP COLUMN IF EXISTS sla_deadline_override;');

    // 4. Chuẩn hóa khóa ngoại bảng ratings
    await q.query('ALTER TABLE ratings DROP CONSTRAINT IF EXISTS fk_ratings_reporter;');
    await q.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'fk_ratings_incident'
        ) THEN
          ALTER TABLE ratings ADD CONSTRAINT fk_ratings_incident 
            FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE;
        END IF;
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'fk_ratings_user'
        ) THEN
          ALTER TABLE ratings ADD CONSTRAINT fk_ratings_user 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        END IF;
      END $$;
    `);
  }

  async down(_q: QueryRunner): Promise<void> {
    // Không cần khôi phục các bảng đã lược bỏ khi dọn dẹp
  }
}

