import assert from 'node:assert/strict';
import test from 'node:test';
import { canViewInternalIncidentData } from './incident.policy';

test('người dân chỉ xem dữ liệu nội bộ của phản ánh mình đã gửi', () => {
  assert.equal(canViewInternalIncidentData({ id: 'u1', role: 'CITIZEN' }, ['u1'], []), true);
  assert.equal(canViewInternalIncidentData({ id: 'u2', role: 'CITIZEN' }, ['u1'], []), false);
});

test('cán bộ khác đơn vị không được xem dữ liệu nội bộ', () => {
  assert.equal(canViewInternalIncidentData(
    { id: 'o1', role: 'OFFICER', department_id: 'd2' },
    [],
    ['d1'],
  ), false);
});

test('admin được xem dữ liệu nội bộ', () => {
  assert.equal(canViewInternalIncidentData({ id: 'a1', role: 'ADMIN' }, [], []), true);
});
