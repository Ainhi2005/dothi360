import { z } from 'zod';

export const registerSchema = z.object({
  full_name: z.string().min(2, 'Tên quá ngắn'),
  email: z.string().email('Email không đúng định dạng').toLowerCase(), // Chuẩn hóa email
  password: z.string().min(6, 'Mật khẩu phải từ 6 ký tự'),
  phone: z.string().optional(),
});

export const loginSchema = z.object({
  email: z.string().email('Email không đúng định dạng').toLowerCase(),
  password: z.string().min(1, 'Mật khẩu không được để trống'),
});

export const refreshSchema = z.object({
  refresh_token: z.string().min(1, 'Refresh token không được để trống'),
});

export const changePasswordSchema = z.object({
  current_password: z.string().min(6, 'Mật khẩu hiện tại phải từ 6 ký tự'),
  new_password: z.string().min(6, 'Mật khẩu mới phải từ 6 ký tự').max(128, 'Mật khẩu tối đa 128 ký tự'),
});
