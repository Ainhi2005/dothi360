// Explicit live deployment smoke test. Secrets stay in ignored local files.
const fs = require('node:fs');
const path = require('node:path');
const { randomBytes } = require('node:crypto');
const dotenv = require('dotenv');
const { Client } = require('pg');
const root = path.resolve(__dirname, '..');
const base = 'https://dothi360.onrender.com';
const accountFile = path.join(root, '.env.live-accounts.local');
const reportFile = path.join(root, 'scratch/render-smoke-report.json');
const initial = dotenv.parse(fs.readFileSync(path.join(root, '.env.demo.local')));
const accounts = fs.existsSync(accountFile) ? dotenv.parse(fs.readFileSync(accountFile)) : {};
for (const role of ['ADMIN', 'OFFICER', 'CITIZEN']) {
  accounts[role + '_EMAIL'] ||= initial[role + '_EMAIL'];
  accounts[role + '_PASSWORD'] ||= randomBytes(24).toString('base64url');
}
fs.writeFileSync(accountFile, Object.entries(accounts).map(([k,v]) => `${k}=${v}`).join('\n') + '\n', { mode: 0o600 });
const report = { base, checked_at: new Date().toISOString(), checks: [] };
function pass(name, detail) { report.checks.push({ name, passed: true, ...detail }); console.log('PASS:', name); }
const tokens = {};
const sessions = [];
async function request(route, role, method = 'GET', body, expected = 200, extra = {}) {
  const headers = { Origin: base, ...(role ? { Authorization: `Bearer ${tokens[role]}` } : {}), ...extra };
  if (body && !(body instanceof FormData)) { headers['Content-Type'] = 'application/json'; body = JSON.stringify(body); }
  const response = await fetch(base + route, { method, headers, body, signal: AbortSignal.timeout(55000) });
  const data = response.headers.get('content-type')?.includes('json') ? await response.json() : await response.text();
  if (response.status !== expected) throw Error(`${method} ${route}: ${response.status}; ${data.message || 'unexpected response'}`);
  return { response, data };
}
async function login(role, password) {
  return request('/api/v1/auth/login', null, 'POST', { email: accounts[role + '_EMAIL'], password }, 200,
    role === 'ADMIN' ? { 'x-client-type': 'admin-web' } : {});
}
async function main() {
  let client;
  try {
    const health = await request('/api/v1/health');
    if (health.data.data.database !== 'connected') throw Error('Database disconnected');
    pass('HTTPS health connects to Neon');
    const html = (await request('/login')).data;
    const assets = [...html.matchAll(/(?:src|href)="(\/assets\/[^\"]+)"/g)].map(m => m[1]);
    for (const asset of assets) await request(asset);
    pass('Admin HTML and bundled assets');
    for (const role of ['ADMIN', 'OFFICER', 'CITIZEN']) {
      let signed;
      try { signed = await login(role, accounts[role + '_PASSWORD']); }
      catch (error) { if (!error.message.includes(': 401;')) throw error; signed = await login(role, initial.DEMO_INITIAL_PASSWORD); }
      tokens[role] = signed.data.data.access_token;
      if (signed.data.data.user.must_change_password) {
        await request('/api/v1/auth/password', role, 'PATCH', { current_password: initial.DEMO_INITIAL_PASSWORD, new_password: accounts[role + '_PASSWORD'] });
        const oldCookie = signed.response.headers.get('set-cookie')?.split(';')[0];
        await request('/api/v1/auth/logout', null, 'POST', signed.data.data.refresh_token ? { refresh_token: signed.data.data.refresh_token } : {}, 200, oldCookie ? { Cookie: oldCookie } : {});
        signed = await login(role, accounts[role + '_PASSWORD']);
        tokens[role] = signed.data.data.access_token;
      }
      const cookie = signed.response.headers.get('set-cookie');
      sessions.push({ role, cookie: cookie?.split(';')[0], refresh: signed.data.data.refresh_token });
      if (role === 'ADMIN' && (!cookie?.includes('Secure') || !cookie?.includes('HttpOnly') || !cookie?.includes('SameSite=Strict'))) throw Error('Admin cookie flags missing');
      await request('/api/v1/auth/me', role);
      pass(`${role} login, password setup, profile`);
    }
    await request('/api/v1/admin/dashboard/summary', 'ADMIN');
    await request('/api/v1/admin/dashboard/summary', 'CITIZEN', 'GET', undefined, 403);
    await request('/api/v1/assignments/officer-dashboard', 'OFFICER');
    await request('/api/v1/incidents/me/reports', 'CITIZEN');
    await request('/api/v1/notifications', 'ADMIN');
    pass('Dashboard, history, notifications, and role isolation');
    if (!process.argv.includes('--workflow')) return;
    const config = dotenv.parse(fs.readFileSync(path.join(root, '.env.neon.local')));
    const url = new URL(config.DATABASE_URL);
    for (const key of ['sslmode','sslcert','sslkey','sslrootcert','uselibpqcompat']) url.searchParams.delete(key);
    client = new Client({ connectionString: url.toString(), ssl: { rejectUnauthorized: true } });
    await client.connect();
    if (process.argv.includes('--resume')) {
      const previous = JSON.parse(fs.readFileSync(reportFile, 'utf8'));
      const id = previous.test_incident_id;
      const incident = (await client.query('SELECT description FROM incidents WHERE id=$1', [id])).rows[0];
      if (!incident?.description.startsWith('[KIỂM THỬ TRIỂN KHAI]')) throw Error('Refusing to resume an unrelated incident');
      const saved = (await client.query('SELECT file_url AS url,mime_type AS type,file_size AS size,storage_key FROM incident_media WHERE incident_id=$1 LIMIT 1', [id])).rows[0];
      saved.size = Number(saved.size);
      report.test_incident_id = id;
      await finishWorkflow(id, saved, incident.description, client);
      return;
    }
    const fixture = (await client.query(`SELECT u.id officer_id,u.department_id,d.incident_type_id FROM users u
      JOIN department_incident_types d ON d.department_id=u.department_id WHERE u.email=$1 LIMIT 1`, [accounts.OFFICER_EMAIL])).rows[0];
    if (!fixture) throw Error('No compatible officer fixture');
    const sample = (await client.query("SELECT file_url FROM incident_media WHERE mime_type='image/jpeg' ORDER BY created_at LIMIT 1")).rows[0];
    const image = await fetch(sample.file_url, { signal: AbortSignal.timeout(30000) });
    if (!image.ok) throw Error('Demo image unavailable');
    const form = new FormData(); form.set('file', new Blob([await image.arrayBuffer()], { type: 'image/jpeg' }), 'deployment-verification.jpg');
    const media = (await request('/api/v1/media/upload', 'CITIZEN', 'POST', form)).data.data;
    pass('Multipart upload to Cloudinary via Render');
    const analyzed = (await request('/api/v1/incidents/analyze', 'CITIZEN', 'POST', { description: 'Ảnh minh họa dùng kiểm tra tích hợp triển khai, không phải phản ánh thực tế.', media_urls: [media] })).data.data;
    pass('Image analysis endpoint returns', { analysis_status: analyzed.analysis_status, telemetry: analyzed.telemetry, manual_review: analyzed.requires_manual_review === true });
    const note = '[KIỂM THỬ TRIỂN KHAI] Hồ sơ thử nghiệm Render + Neon, không phải sự cố thực tế.';
    const body = { incident_type_id: fixture.incident_type_id, description: note, longitude: 105.745321, latitude: 20.965432,
      location_source: 'MAP', reported_severity: 2, media_urls: [media], ai_analysis: { ...analyzed, requires_manual_review: false },
      ai_confirmation: { accepted: true, confirmed_incident_type_id: fixture.incident_type_id, confirmed_severity: 2,
        confirmed_summary: note, summary_edited: true, confirmed_at: new Date().toISOString() } };
    const created = (await request('/api/v1/incidents', 'CITIZEN', 'POST', body, 201)).data.data;
    const id = created.incident.id; report.test_incident_id = id;
    const repeated = (await request('/api/v1/incidents', 'CITIZEN', 'POST', body, 201)).data.data;
    if (repeated.incident.id !== id) throw Error('Repeated report was not deduplicated');
    pass('Create report and same-reporter duplicate prevention');
    const assignment = (await request('/api/v1/assignments/assign-officer', 'ADMIN', 'POST', { incident_id: id, ...fixture, reason: note })).data.data;
    await request(`/api/v1/assignments/${assignment.id}/accept`, 'OFFICER', 'POST', {});
    await request(`/api/v1/incidents/${id}/status`, 'OFFICER', 'PATCH', { status: 'IN_PROGRESS', note });
    pass('Admin assignment, officer acceptance and start');
    await finishWorkflow(id, media, note, client);
  } finally {
    for (const session of sessions) {
      try { await request('/api/v1/auth/logout', null, 'POST', session.refresh ? { refresh_token: session.refresh } : {}, 200, session.cookie ? { Cookie: session.cookie } : {}); } catch {}
    }
    if (client) await client.end();
    fs.mkdirSync(path.dirname(reportFile), { recursive: true });
    fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));
  }
}
async function finishWorkflow(id, media, note, client) {
  const checklist = (await request(`/api/v1/officer-operations/incidents/${id}/checklist`, 'OFFICER')).data.data;
  await request(`/api/v1/officer-operations/incidents/${id}/checklist`, 'OFFICER', 'PUT', { items: checklist.map(item => ({ id: item.id, completed: true, note })) });
  await request(`/api/v1/incidents/${id}/progress`, 'OFFICER', 'POST', { note, progress_percent: 90, visibility: 'PUBLIC' }, 201);
  const submit = async () => {
    // Each submission uploads its own evidence, as the mobile app does. A stored
    // report photo's unique storage_key cannot be inserted again as new evidence.
    const source = await fetch(media.url, { signal: AbortSignal.timeout(30000) });
    if (!source.ok) throw Error('Evidence sample unavailable');
    const form = new FormData();
    form.set('file', new Blob([await source.arrayBuffer()], { type: media.type }), 'verification-evidence.jpg');
    const evidence = (await request('/api/v1/media/upload', 'OFFICER', 'POST', form)).data.data;
    return request(`/api/v1/incidents/${id}/status`, 'OFFICER', 'PATCH', { status: 'PENDING_VERIFICATION', note, media_urls: [evidence] });
  };
  await submit();
  const notification = (await client.query("SELECT count(*)::int n FROM notifications WHERE incident_id=$1 AND type='INCIDENT_PENDING_VERIFICATION'", [id])).rows[0];
  if (!notification.n) throw Error('Missing Admin verification notification');
  pass('Checklist, progress, verification submission and Admin notification');
  await request(`/api/v1/incidents/${id}/verification`, 'ADMIN', 'PATCH', { decision: 'REWORK', note });
  await submit();
  await request(`/api/v1/incidents/${id}/verification`, 'ADMIN', 'PATCH', { decision: 'APPROVE', note });
  await request(`/api/v1/incidents/${id}/verification`, 'ADMIN', 'PATCH', { decision: 'APPROVE', note }, 409);
  const final = (await client.query('SELECT status,resolved_at FROM incidents WHERE id=$1', [id])).rows[0];
  if (final.status !== 'RESOLVED' || !final.resolved_at) throw Error('Final state invalid');
  pass('REWORK, resubmit, APPROVE and stale-decision rejection');
}
main().catch(error => { report.error = error.code || error.message; fs.writeFileSync(reportFile, JSON.stringify(report, null, 2)); console.error(report.error); process.exitCode = 1; });
