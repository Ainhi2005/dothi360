import assert from 'node:assert/strict';
import test from 'node:test';
import { assertUserIsActive, isRefreshTokenUsable } from './auth.policy';

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
