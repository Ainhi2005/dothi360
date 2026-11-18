import { z } from 'zod';

export const reassignSchema = z.object({
  incident_id: z.string().uuid('ID sự cố không hợp lệ'),
  new_department_id: z.string().uuid('ID đơn vị mới không hợp lệ'),
  reason: z.string().min(5, 'Vui lòng cung cấp lý do (ít nhất 5 ký tự)'),
});

export const rejectAssignmentSchema = z.object({
  reason_code: z.enum([
    'OUT_OF_SCOPE',
    'WRONG_LOCATION',
    'LACK_RESOURCES',
    'SAFETY_RISK',
    'ALREADY_RESOLVED',
    'OTHER',
  ]),
  reason: z.string().trim().min(5, 'Lý do từ chối cần ít nhất 5 ký tự').max(1000),
});
