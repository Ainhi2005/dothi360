// Smoke checks using the deployed DB and actual Express routes; no background push jobs.
const fs = require('node:fs');
const path = require('node:path');
const dotenv = require('dotenv');
const root = path.resolve(__dirname, '..');
Object.assign(process.env, dotenv.parse(fs.readFileSync(path.join(root, '.env'))),
  dotenv.parse(fs.readFileSync(path.join(root, '.env.neon.local'))), { NODE_ENV: 'test', SERVE_ADMIN: 'true' });
const credentials = dotenv.parse(fs.readFileSync(path.join(root, '.env.demo.local')));
const { AppDataSource } = require('../dist/database/data-source');
const app = require('../dist/app').default;
async function main() {
  let server;
  try {
    AppDataSource.setOptions({ logging: false });
    await AppDataSource.initialize();
    for (const entity of AppDataSource.entityMetadatas) await AppDataSource.getRepository(entity.target).find({ take: 1 });
    console.log('PASS: all ORM entities query Neon');
    if (await AppDataSource.showMigrations()) throw Error('Unexpected pending migrations');
    console.log('PASS: snapshot migration baseline');
    server = await new Promise(resolve => { const s = app.listen(0, '127.0.0.1', () => resolve(s)); });
    const base = `http://127.0.0.1:${server.address().port}`;
    async function request(route, options = {}) {
      const response = await fetch(base + route, options);
      if (!response.ok) throw Error(`HTTP check failed: ${route} ${response.status}`);
      return response;
    }
    const health = await (await request('/api/v1/health')).json();
    if (health.data.database !== 'connected') throw Error('Health database disconnected');
    await request('/login');
    console.log('PASS: health and Admin HTML route');
    const headers = { 'Content-Type': 'application/json', 'x-client-type': 'admin-web' };
    const login = await request('/api/v1/auth/login', { method: 'POST', headers, body: JSON.stringify({ email: credentials.ADMIN_EMAIL, password: credentials.DEMO_INITIAL_PASSWORD }) });
    const result = await login.json();
    const cookie = login.headers.get('set-cookie')?.split(';')[0];
    if (!cookie || !result.data.access_token || result.data.refresh_token) throw Error('Invalid Admin cookie login');
    const authHeaders = { Authorization: `Bearer ${result.data.access_token}` };
    await request('/api/v1/auth/me', { headers: authHeaders });
    console.log('PASS: Admin login and authenticated profile');
    const refreshed = await request('/api/v1/auth/refresh', { method: 'POST', headers: { ...headers, Cookie: cookie }, body: '{}' });
    const newCookie = refreshed.headers.get('set-cookie')?.split(';')[0];
    await request('/api/v1/auth/logout', { method: 'POST', headers: { ...headers, Cookie: newCookie || cookie }, body: '{}' });
    console.log('PASS: refresh and logout');
  } finally {
    if (server) await new Promise(resolve => server.close(resolve));
    if (AppDataSource.isInitialized) await AppDataSource.destroy();
  }
}
main().catch(error => { console.error(error.code ? `Verification failed: ${error.code}` : error.message); process.exitCode = 1; });
