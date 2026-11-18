import assert from 'node:assert/strict';
import test from 'node:test';
import { canOfficerTransitionIncident, canTransitionIncident } from './incident-status';

test('chỉ cho phép chuỗi trạng thái xử lý hợp lệ', () => {
  assert.equal(canTransitionIncident('ASSIGNED', 'ACCEPTED'), true);
  assert.equal(canTransitionIncident('ASSIGNED', 'IN_PROGRESS'), true);
  assert.equal(canTransitionIncident('ACCEPTED', 'IN_PROGRESS'), true);
  assert.equal(canTransitionIncident('IN_PROGRESS', 'PENDING_VERIFICATION'), true);
  assert.equal(canTransitionIncident('PENDING_VERIFICATION', 'RESOLVED'), true);
});

test('không cho bỏ bước hoặc mở lại trạng thái kết thúc', () => {
  assert.equal(canTransitionIncident('ASSIGNED', 'RESOLVED'), false);
  assert.equal(canTransitionIncident('RESOLVED', 'IN_PROGRESS'), false);
  assert.equal(canTransitionIncident('UNKNOWN', 'RESOLVED'), false);
});

test('cán bộ chỉ được cập nhật theo luồng xử lý hiện trường', () => {
  assert.equal(canOfficerTransitionIncident('ASSIGNED', 'IN_PROGRESS'), true);
  assert.equal(canOfficerTransitionIncident('ACCEPTED', 'IN_PROGRESS'), true);
  assert.equal(canOfficerTransitionIncident('IN_PROGRESS', 'PENDING_VERIFICATION'), true);
  assert.equal(canOfficerTransitionIncident('IN_PROGRESS', 'RESOLVED'), false);
  assert.equal(canOfficerTransitionIncident('ACCEPTED', 'REJECTED'), false);
  assert.equal(canOfficerTransitionIncident('IN_PROGRESS', 'CANCELLED'), false);
});
