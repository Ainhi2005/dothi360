import assert from 'node:assert/strict';
import test, { before, after } from 'node:test';
import { randomUUID } from 'node:crypto';
import type { Server } from 'node:http';
import app from '../../app';
import { AppDataSource } from '../../database/data-source';
import { User } from './user.entity';
import { UserService } from './user.service';

let server: Server, base: string, adminToken: string;
const users: Record<string, { id: string; email: string; password: string }> = {};
const initialPassword = 'Integration-before-2026!';
async function call(route: string, token?: string, method = 'GET', body?: unknown) {
  const response = await fetch(base + route, { method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body) });
  return { status: response.status, body: await response.json() };
}
async function login(key: string, password = users[key].password) {
  return call('/auth/login', undefined, 'POST', { email: users[key].email, password });
}
before(async () => {
  AppDataSource.setOptions({ logging: false });
  await AppDataSource.initialize();
  server = await new Promise<Server>(resolve => { const s = app.listen(0, '127.0.0.1', () => resolve(s)); });
  base = `http://127.0.0.1:${(server.address() as { port: number }).port}/api/v1`;
  for (const [key, role] of [['actor', 'ADMIN'], ['admin', 'ADMIN'], ['citizen', 'CITIZEN'], ['officer', 'OFFICER']]) {
    const email = `password-test-${randomUUID()}@example.test`;
    const department = role === 'OFFICER' ? (await AppDataSource.query('SELECT id FROM departments WHERE is_active=TRUE LIMIT 1'))[0]?.id : undefined;
    const created = await new UserService().create({ full_name: 'Password integration fixture', email, role, password: initialPassword, department_id: department });
    users[key] = { id: created.id, email, password: initialPassword };
    await AppDataSource.getRepository(User).update(created.id, { must_change_password: false });
  }
  adminToken = (await login('actor')).body.data.access_token;
});
after(async () => {
  if (server) await new Promise<void>(resolve => server.close(() => resolve()));
  const ids = Object.values(users).map(user => user.id);
  if (AppDataSource.isInitialized && ids.length) {
    await AppDataSource.transaction(async manager => {
      await manager.query('DELETE FROM audit_logs WHERE user_id = ANY($1::uuid[]) OR entity_id = ANY($1::uuid[])', [ids]);
      await manager.query('DELETE FROM refresh_tokens WHERE user_id = ANY($1::uuid[])', [ids]);
      await manager.query('DELETE FROM users WHERE id = ANY($1::uuid[])', [ids]);
    });
  }
  if (AppDataSource.isInitialized) await AppDataSource.destroy();
});

test('chỉ ADMIN được đặt mật khẩu; từ chối người chưa đăng nhập và người dân', async () => {
  const route = `/users/${users.admin.id}/password`, body = { new_password: 'Not-allowed-2026!' };
  assert.equal((await call(route, undefined, 'PATCH', body)).status, 401);
  const citizen = (await login('citizen')).body.data.access_token;
  assert.equal((await call(route, citizen, 'PATCH', body)).status, 403);
  assert.equal((await login('admin')).status, 200);
});
test('kiểm tra độ dài mật khẩu và tài khoản đích', async () => {
  for (const password of ['short', 'x'.repeat(129)]) assert.equal((await call(`/users/${users.admin.id}/password`, adminToken, 'PATCH', { new_password: password })).status, 400);
  assert.equal((await call('/users/invalid/password', adminToken, 'PATCH', { new_password: initialPassword })).status, 400);
  assert.equal((await call(`/users/${randomUUID()}/password`, adminToken, 'PATCH', { new_password: initialPassword })).status, 404);
});
test('đổi cho CITIZEN, OFFICER và ADMIN; thu hồi access/refresh cũ ngay', async () => {
  for (const key of ['citizen', 'officer', 'admin']) {
    const old = (await login(key)).body.data;
    const password = `Changed-${key}-2026!`;
    const result = await call(`/users/${users[key].id}/password`, adminToken, 'PATCH', { new_password: password });
    assert.equal(result.status, 200);
    assert.equal(result.body.data.requires_relogin, false);
    assert.equal((await login(key, initialPassword)).status, 401);
    assert.equal((await call('/auth/me', old.access_token)).status, 401);
    assert.equal((await call('/auth/refresh', undefined, 'POST', { refresh_token: old.refresh_token })).status, 401);
    users[key].password = password;
    const fresh = await login(key);
    assert.equal(fresh.status, 200);
    assert.equal((await call('/auth/me', fresh.body.data.access_token)).status, 200);
  }
  assert.equal((await call('/users', adminToken)).status, 200);
});
test('audit ghi người thực hiện và đích nhưng không chứa mật khẩu hoặc hash', async () => {
  const rows = await AppDataSource.query("SELECT * FROM audit_logs WHERE user_id=$1 AND action='USER_PASSWORD_RESET'", [users.actor.id]);
  assert.equal(rows.length, 3);
  const text = JSON.stringify(rows);
  for (const key of ['citizen', 'officer', 'admin']) assert.ok(!text.includes(users[key].password));
  assert.ok(!text.includes('password_hash'));
});
test('bắt buộc đổi lại mật khẩu và sau đó thu hồi cả phiên đổi mật khẩu', async () => {
  const temporary = 'Temporary-citizen-2026!';
  await call(`/users/${users.citizen.id}/password`, adminToken, 'PATCH', { new_password: temporary, must_change_password: true });
  users.citizen.password = temporary;
  const signed = (await login('citizen')).body.data;
  assert.equal(signed.user.must_change_password, true);
  assert.equal((await call('/notifications', signed.access_token)).status, 428);
  assert.equal((await call('/auth/me', signed.access_token)).status, 200);
  users.citizen.password = 'Personal-citizen-2026!';
  assert.equal((await call('/auth/password', signed.access_token, 'PATCH', { current_password: temporary, new_password: users.citizen.password })).status, 200);
  assert.equal((await call('/auth/me', signed.access_token)).status, 401);
  const signedAgain = await login('citizen');
  assert.equal(signedAgain.body.data.user.must_change_password, false);
});
test('refresh chạy đồng thời không giữ lại được phiên sau reset', async () => {
  const old = (await login('officer')).body.data;
  users.officer.password = 'Concurrent-officer-2026!';
  const [reset, refresh] = await Promise.all([
    call(`/users/${users.officer.id}/password`, adminToken, 'PATCH', { new_password: users.officer.password }),
    call('/auth/refresh', undefined, 'POST', { refresh_token: old.refresh_token }),
  ]);
  assert.equal(reset.status, 200);
  assert.ok([200, 401].includes(refresh.status));
  if (refresh.status === 200) {
    assert.equal((await call('/auth/me', refresh.body.data.access_token)).status, 401);
    assert.equal((await call('/auth/refresh', undefined, 'POST', { refresh_token: refresh.body.data.refresh_token })).status, 401);
  }
});
test('ADMIN đổi mật khẩu của chính mình phải đăng nhập lại', async () => {
  const old = (await login('actor')).body.data;
  users.actor.password = 'Changed-self-admin-2026!';
  const result = await call(`/users/${users.actor.id}/password`, adminToken, 'PATCH', { new_password: users.actor.password });
  assert.equal(result.status, 200);
  assert.equal(result.body.data.requires_relogin, true);
  assert.equal((await call('/users', adminToken)).status, 401);
  assert.equal((await call('/auth/refresh', undefined, 'POST', { refresh_token: old.refresh_token })).status, 401);
  assert.equal((await login('actor')).status, 200);
});
