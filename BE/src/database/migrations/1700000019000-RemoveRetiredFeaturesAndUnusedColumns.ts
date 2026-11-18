import { MigrationInterface, QueryRunner } from 'typeorm';

export class RemoveRetiredFeaturesAndUnusedColumns1700000019000 implements MigrationInterface {
  name = 'RemoveRetiredFeaturesAndUnusedColumns1700000019000';

  async up(q: QueryRunner): Promise<void> {
    // No CASCADE: an unexpected external dependency must stop the migration.
    await q.query('DROP TABLE IF EXISTS public.ratings');
    await q.query('DROP TABLE IF EXISTS public.coordination_requests');

    // These metadata fields have no writers/readers in the current application.
    // Stop rather than silently discard populated fields in another environment.
    const unusedColumns: Record<string, string[]> = {
      users: ['last_login_at'],
      refresh_tokens: ['user_agent', 'ip_address'],
      audit_logs: ['request_id', 'ip_address', 'user_agent'],
    };
    for (const [table, columns] of Object.entries(unusedColumns)) {
      for (const column of columns) {
        if (!(await q.hasColumn(table, column))) continue;
        const [row] = await q.query(`SELECT COUNT(*)::int AS count FROM "${table}" WHERE "${column}" IS NOT NULL`);
        if (row.count > 0) {
          throw new Error(`Cannot remove populated legacy field ${table}.${column}; back up and review its data first`);
        }
        await q.query(`ALTER TABLE "${table}" DROP COLUMN "${column}"`);
      }
    }

    // Duplicate detection now uses constants, not this abandoned configuration.
    await q.query("DELETE FROM algorithm_configs WHERE config_key = 'DUPLICATE_DETECTION'");
  }

  async down(): Promise<void> {
    throw new Error('This cleanup removes retired data. Restore the pre-cleanup database backup to roll it back.');
  }
}
