import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import express from 'express';
import { mountAdmin } from './admin-static';

test('same-origin Admin serves routes/assets without swallowing API or asset errors', async () => {
  const directory = mkdtempSync(path.join(tmpdir(), 'dothi-admin-test-'));
  mkdirSync(path.join(directory, 'assets'));
  writeFileSync(path.join(directory, 'index.html'), '<html>Admin deploy test</html>');
  writeFileSync(path.join(directory, 'assets', 'app.js'), 'console.log("demo");');
  const app = express();
  app.get('/api/v1/example', (_req, res) => { res.json({ success: true }); });
  mountAdmin(app, directory, true);
  app.use((_req, res) => { res.status(404).json({ success: false }); });
  const server = app.listen(0, '127.0.0.1');
  await new Promise<void>(resolve => server.once('listening', resolve));
  const address = server.address();
  assert.ok(address && typeof address !== 'string');
  const base = `http://127.0.0.1:${address.port}`;
  try {
    for (const route of ['/', '/incidents/demo-id', '/citizen-feedbacks?feedbackId=demo']) {
      const r = await fetch(base + route, { headers: { Accept: 'text/html' } });
      assert.equal(r.status, 200);
      assert.match(await r.text(), /Admin deploy test/);
      assert.equal(r.headers.get('cache-control'), 'no-cache');
      assert.match(r.headers.get('content-security-policy')!, /img-src 'self' data: blob: https:/);
    }
    assert.equal((await fetch(base + '/assets/app.js')).status, 200);
    for (const route of ['/api/v1/missing', '/assets/missing.js', '/uploads/missing.jpg']) {
      const r = await fetch(base + route);
      assert.equal(r.status, 404);
      assert.equal((await r.json()).success, false);
    }
    assert.deepEqual(await (await fetch(base + '/api/v1/example')).json(), { success: true });
    assert.equal((await fetch(base + '/incidents/demo', { method: 'POST' })).status, 404);
  } finally {
    server.closeAllConnections();
    await new Promise<void>(resolve => server.close(() => resolve()));
    rmSync(directory, { recursive: true });
  }
});

test('combined hosting fails early when Admin build is missing', () => {
  assert.throws(() => mountAdmin(express(), path.join(tmpdir(), 'missing-admin-dothi-360'), false), /Thiếu bản build Admin/);
});
