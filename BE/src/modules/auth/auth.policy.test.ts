import assert from 'node:assert/strict';
import test from 'node:test';
import { assertUserIsActive, isRefreshTokenUsable } from './auth.policy';
import { changePasswordSchema, registerSchema } from './auth.validation';
import { resetUserPasswordSchema, createUserSchema } from '../users/user.validation';

test('thống nhất mật khẩu tối thiểu 6 ký tự cho đăng ký và đổi mật khẩu', () => {
  for (const password of ['123456', 'abcdef']) {
    assert.equal(changePasswordSchema.safeParse({ current_password: 'old123', new_password: password }).success, true);
    assert.equal(resetUserPasswordSchema.safeParse({ new_password: password }).success, true);
    assert.equal(registerSchema.safeParse({ full_name: 'Test User', email: 'test@example.test', password }).success, true);
    assert.equal(createUserSchema.safeParse({ full_name: 'Test User', email: 'test@example.test', password, role: 'ADMIN' }).success, true);
  }
  assert.equal(changePasswordSchema.safeParse({ current_password: 'old123', new_password: '12345' }).success, false);
  assert.equal(resetUserPasswordSchema.safeParse({ new_password: '12345' }).success, false);
});

test('từ chối tài khoản đã khóa', () => {
  assert.throws(() => assertUserIsActive({ is_active: false }), (error: any) => error.statusCode === 403);
  assert.doesNotThrow(() => assertUserIsActive({ is_active: true }));
});

test('refresh token phải còn hạn và chưa bị thu hồi', () => {
  const now = new Date('2026-01-01T00:00:00Z');
  assert.equal(isRefreshTokenUsable({ revoked_at: null, expires_at: new Date('2026-01-02T00:00:00Z') }, now), true);
  assert.equal(isRefreshTokenUsable({ revoked_at: now, expires_at: new Date('2026-01-02T00:00:00Z') }, now), false);
  assert.equal(isRefreshTokenUsable({ revoked_at: null, expires_at: new Date('2025-12-31T00:00:00Z') }, now), false);
});
