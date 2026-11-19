import assert from 'node:assert/strict';
import test, { before, after } from 'node:test';
import { randomUUID } from 'node:crypto';
import { AppDataSource } from '../../database/data-source';
import { readUserReports } from './chat.service';

before(async () => { await AppDataSource.initialize(); });
after(async () => { if (AppDataSource.isInitialized) await AppDataSource.destroy(); });
test('truy vấn chat đọc đúng report của người gọi, không lỗi quan hệ ORM', async () => {
  const [sample] = await AppDataSource.query('SELECT reporter_id FROM incident_reports LIMIT 1');
  assert.ok(sample, 'Need seeded reports');
  const expected = await AppDataSource.query('SELECT incident_id FROM incident_reports WHERE reporter_id=$1', [sample.reporter_id]);
  const ids = new Set(expected.map((row: { incident_id: string }) => row.incident_id));
  const rows = await readUserReports(sample.reporter_id, 10);
  assert.ok(rows.length > 0 && rows.length <= 10);
  for (const row of rows) { assert.ok(ids.has(row.id)); assert.match(row.incident_code, /^#PA-\d{4}-[A-F0-9]{3}$/); }
  assert.equal((await readUserReports(sample.reporter_id, 1)).length, 1);
  assert.deepEqual(await readUserReports(randomUUID(), 10), []);
  const active = await readUserReports(sample.reporter_id, 10, 'IN_PROGRESS');
  for (const row of active) assert.equal(row.status, 'IN_PROGRESS');
});
