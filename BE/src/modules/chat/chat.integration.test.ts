import assert from 'node:assert/strict';
import test, { before, after } from 'node:test';
import { randomUUID } from 'node:crypto';
import type { Server } from 'node:http';
import jwt from 'jsonwebtoken';
import app from '../../app';
import { env } from '../../config/env';
import { credentialVersion } from '../auth/credential-version';
import { chatCatalog } from './chat.catalog';
import { AppDataSource } from '../../database/data-source';
import { readUserReports } from './chat.service';

let server: Server, base: string, token: string;
before(async () => {
  await AppDataSource.initialize();
  const [user] = await AppDataSource.query("SELECT * FROM users WHERE is_active=TRUE AND must_change_password=FALSE LIMIT 1");
  assert.ok(user);
  token = jwt.sign({ id: user.id, credential_version: credentialVersion(user.password_hash) }, env.JWT_ACCESS_SECRET, { expiresIn: '2m' });
  server = await new Promise<Server>(resolve => { const instance = app.listen(0, '127.0.0.1', () => resolve(instance)); });
  base = `http://127.0.0.1:${(server.address() as { port: number }).port}/api/v1/chat`;
});
after(async () => {
  if (server) await new Promise<void>(resolve => server.close(() => resolve()));
  if (AppDataSource.isInitialized) await AppDataSource.destroy();
});
test('API bộ gợi ý cần đăng nhập và mọi câu gợi ý trả lời không gọi AI', async () => {
  assert.equal((await fetch(base + '/suggestions')).status, 401);
  const catalog = await fetch(base + '/suggestions', { headers: { Authorization: `Bearer ${token}` } });
  assert.equal(catalog.status, 200);
  assert.equal((await catalog.json()).data.length, chatCatalog.length);
  for (const item of chatCatalog) {
    const response = await fetch(base, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ message: item.question, suggestion_id: item.id, userId: randomUUID() }) });
    assert.equal(response.status, 200, item.id);
    const body = await response.json();
    assert.equal(body.data.intent, item.id); assert.equal(body.data.ai_used, false); assert.equal(body.data.model, null);
  }
});
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
