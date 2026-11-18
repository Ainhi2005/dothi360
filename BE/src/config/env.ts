/** Đọc, kiểm tra và cung cấp biến môi trường; ứng dụng phải dừng sớm nếu thiếu cấu hình bắt buộc. */
import { z } from 'zod';
import dotenv from 'dotenv';

// Đọc biến môi trường từ file .env
dotenv.config();

// Định nghĩa schema để bắt buộc các biến này phải có và đúng kiểu dữ liệu
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.string().default('3000'),
  DATABASE_URL: z.string().url().optional(),
  DB_HOST: z.string().optional(),
  DB_PORT: z.coerce.number().int().min(1).max(65535).default(5432),
  DB_USER: z.string().optional(),
  DB_PASSWORD: z.string().optional(),
  DB_NAME: z.string().optional(),
  DB_SSL: z.enum(['true', 'false']).optional(),
  SERVE_ADMIN: z.enum(['true', 'false']).default('false'),
  PUBLIC_APP_URL: z.url().optional(),
  RENDER_EXTERNAL_URL: z.url().optional(),
  JWT_ACCESS_SECRET: z.string().min(1).default('development-access-secret-change-me-now'),
  JWT_ACCESS_EXPIRES_IN: z.string().default('1h'),
  JWT_REFRESH_SECRET: z.string().min(1).default('development-refresh-secret-change-me'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('7d'),
  CORS_ORIGINS: z.string().default('http://localhost:5173'),
  CLOUDINARY_CLOUD_NAME: z.string().optional(),
  CLOUDINARY_API_KEY: z.string().optional(),
  CLOUDINARY_API_SECRET: z.string().optional(),
  CLOUDINARY_FOLDER: z.string().default('urban-incidents'),
  GEMINI_API_KEY: z.string().optional(),
  GEMINI_MODEL: z.string().default('gemini-3.5-flash-lite'),
  GEMINI_FALLBACK_MODELS: z.string().default('gemini-3.5-flash'),
  AI_ALLOWED_MEDIA_HOSTS: z.string().default('res.cloudinary.com'),
  FIREBASE_SERVICE_ACCOUNT_BASE64: z.string().optional(),
  GEOCODING_BASE_URL: z.url().default('https://photon.komoot.io'),
}).superRefine((value, context) => {
  if (value.DATABASE_URL) {
    if (!['postgres:', 'postgresql:'].includes(new URL(value.DATABASE_URL).protocol)) {
      context.addIssue({ code: 'custom', path: ['DATABASE_URL'], message: 'DATABASE_URL phải dùng postgres:// hoặc postgresql://' });
    }
  } else {
    for (const name of ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME'] as const) {
      if (!value[name]) context.addIssue({ code: 'custom', path: [name], message: `${name} là bắt buộc khi không có DATABASE_URL` });
    }
  }
  if (value.NODE_ENV !== 'production') return;
  if (value.JWT_ACCESS_SECRET.length < 32 || value.JWT_ACCESS_SECRET.startsWith('development-')) {
    context.addIssue({ code: 'custom', path: ['JWT_ACCESS_SECRET'], message: 'JWT_ACCESS_SECRET production phải có ít nhất 32 ký tự và không dùng mặc định' });
  }
  if (value.JWT_REFRESH_SECRET.length < 32 || value.JWT_REFRESH_SECRET.startsWith('development-')) {
    context.addIssue({ code: 'custom', path: ['JWT_REFRESH_SECRET'], message: 'JWT_REFRESH_SECRET production phải có ít nhất 32 ký tự và không dùng mặc định' });
  }
  const required = [
    ['CLOUDINARY_CLOUD_NAME', value.CLOUDINARY_CLOUD_NAME],
    ['CLOUDINARY_API_KEY', value.CLOUDINARY_API_KEY],
    ['CLOUDINARY_API_SECRET', value.CLOUDINARY_API_SECRET],
    ['GEMINI_API_KEY', value.GEMINI_API_KEY],
    ['FIREBASE_SERVICE_ACCOUNT_BASE64', value.FIREBASE_SERVICE_ACCOUNT_BASE64],
  ] as const;
  for (const [name, configuredValue] of required) {
    if (!configuredValue) {
      context.addIssue({ code: 'custom', path: [name], message: `${name} là bắt buộc trên production` });
    }
  }
});

// Validate process.env
const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error('❌ Lỗi cấu hình biến môi trường (.env):', parsedEnv.error.format());
  process.exit(1);
}

// Export config ra để dùng ở các file khác
export const env = parsedEnv.data;

export const corsOrigins = [...new Set([
  ...env.CORS_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean),
  ...[env.PUBLIC_APP_URL, env.RENDER_EXTERNAL_URL].filter((url): url is string => Boolean(url)).map(url => new URL(url).origin),
])];
export const aiAllowedMediaHosts = env.AI_ALLOWED_MEDIA_HOSTS.split(',').map((host) => host.trim().toLowerCase()).filter(Boolean);
export const geminiModels = [env.GEMINI_MODEL, ...env.GEMINI_FALLBACK_MODELS.split(',')]
  .map((model) => model.trim())
  .filter((model, index, models) => Boolean(model) && models.indexOf(model) === index);
