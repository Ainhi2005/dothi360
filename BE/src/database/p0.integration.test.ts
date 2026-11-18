import assert from 'node:assert/strict';
import test, { after, before } from 'node:test';
import { AppDataSource } from './data-source';
import { IncidentService } from '../modules/incidents/incident.service';
import { AdminDashboardService } from '../modules/admin/admin-dashboard.service';

before(async () => {
  await AppDataSource.initialize();
});

after(async () => {
  if (AppDataSource.isInitialized) await AppDataSource.destroy();
});

test('database có đủ migration P0', async () => {
  const rows = await AppDataSource.query('SELECT name FROM migrations ORDER BY timestamp');
  const applied = new Set(rows.map((row: { name: string }) => row.name));
  for (const name of [
    'InitialSchema1700000000000',
    'AlignRefreshTokens1700000001000',
    'RecordLegacyBaseline1700000002000',
    'EnforceConcurrencyConstraints1700000003000',
    'SecurityHardening1700000004000',
    'RetireCoordinationChecklist1700000018000',
    'RemoveRetiredFeaturesAndUnusedColumns1700000019000',
  ]) assert.equal(applied.has(name), true, `Missing migration: ${name}`);
});

test('database đã loại bỏ tính năng và metadata không còn sử dụng', async () => {
  const [tables] = await AppDataSource.query(`SELECT
    to_regclass('public.ratings') AS ratings,
    to_regclass('public.coordination_requests') AS coordination`);
  assert.equal(tables.ratings, null);
  assert.equal(tables.coordination, null);
  const columns = await AppDataSource.query(`SELECT table_name,column_name
    FROM information_schema.columns WHERE table_schema='public' AND (
      (table_name='users' AND column_name='last_login_at') OR
      (table_name='refresh_tokens' AND column_name IN ('user_agent','ip_address')) OR
      (table_name='audit_logs' AND column_name IN ('request_id','user_agent','ip_address')))`);
  assert.equal(columns.length, 0);
  const [config] = await AppDataSource.query("SELECT COUNT(*)::int count FROM algorithm_configs WHERE config_key='DUPLICATE_DETECTION'");
  assert.equal(config.count, 0);
});

test('database chống assignment đang hoạt động và report trùng', async () => {
  const rows = await AppDataSource.query(`
    SELECT indexname
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname IN (
        'uq_incident_assignments_current',
        'uq_incident_reports_incident_reporter'
      )
  `);
  const indexes = new Set(rows.map((row: { indexname: string }) => row.indexname));
  assert.equal(indexes.has('uq_incident_assignments_current'), true);
  assert.equal(indexes.has('uq_incident_reports_incident_reporter'), true);
});

test('refresh token sử dụng revoked_at thay cho cờ boolean cũ', async () => {
  const rows = await AppDataSource.query(`
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'refresh_tokens'
  `);
  const columns = new Set(rows.map((row: { column_name: string }) => row.column_name));
  assert.equal(columns.has('revoked_at'), true);
  assert.equal(columns.has('is_revoked'), false);
});

test('ORM và các truy vấn danh sách/thống kê đọc được schema sau dọn dẹp', async () => {
  for (const metadata of AppDataSource.entityMetadatas) {
    await AppDataSource.getRepository(metadata.target).find({ take: 1 });
  }
  const incidents = await new IncidentService().findAll({ page: 1, limit: 5 });
  assert.ok(Array.isArray(incidents.data));
  const dashboard = new AdminDashboardService();
  await dashboard.summary();
  const workload = await dashboard.workload();
  assert.ok(Array.isArray(workload));
});
