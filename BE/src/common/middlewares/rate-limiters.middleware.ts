import rateLimit from 'express-rate-limit';
import { env } from '../../config/env';

const isDev = env.NODE_ENV === 'development';
const make = (windowMs: number, max: number, message: string) =>
  rateLimit({
    windowMs,
    max: isDev ? 5000 : max,
    skip: () => isDev,
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, message },
  });

export const apiLimiter = make(15 * 60_000, 600, 'Quá nhiều yêu cầu, vui lòng thử lại sau');
export const loginLimiter = make(15 * 60_000, 50, 'Đăng nhập quá nhiều lần, vui lòng chờ 15 phút');
export const uploadLimiter = make(15 * 60_000, 30, 'Đã vượt giới hạn tải media');
export const chatLimiter = make(60_000, 30, 'Bạn đang gửi tin nhắn quá nhanh');
export const reportLimiter = make(60 * 60_000, 50, 'Đã vượt giới hạn gửi phản ánh');

