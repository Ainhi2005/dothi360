import { z } from 'zod';
import { ROLES } from '../../common/constants/roles';

export const resetUserPasswordSchema = z.object({
  new_password: z.string().min(6, 'Mật khẩu mới phải từ 6 ký tự').max(128, 'Mật khẩu tối đa 128 ký tự'),
  must_change_password: z.boolean().default(false),
});

export const createUserSchema = z.object({
  full_name: z.string().min(2, 'Tên quá ngắn'),
  email: z.string().email('Email không đúng định dạng').toLowerCase(),
  password: z.string().min(6, 'Mật khẩu phải từ 6 ký tự'),
  phone: z.string().optional(),
  role: z.enum([ROLES.CITIZEN, ROLES.OFFICER, ROLES.ADMIN]),
  department_id: z.string().uuid('ID đơn vị không hợp lệ').optional(),
});

export const updateUserSchema = z.object({
  full_name: z.string().min(2, 'Tên quá ngắn').optional(),
  phone: z.string().optional(),
  role: z.enum([ROLES.CITIZEN, ROLES.OFFICER, ROLES.ADMIN]).optional(),
  department_id: z.string().uuid('ID đơn vị không hợp lệ').optional().nullable(),
  is_active: z.boolean().optional(),
});

export const updateProfileSchema = z.object({
  full_name: z.string().min(2, 'Tên quá ngắn').optional(),
  phone: z.string().max(20, 'Số điện thoại quá dài').optional(),
});
