import { z } from 'zod';

const phoneSchema = z.object({
  label: z.string().trim().min(1).max(100),
  number: z.string().trim().regex(/^[0-9+ ]{3,20}$/, 'Số điện thoại không hợp lệ'),
});

export const emergencyGuideSchema = z.object({
  code: z.string().trim().min(2).max(60).regex(/^[A-Z0-9_]+$/),
  title: z.string().trim().min(3).max(160),
  summary: z.string().trim().min(3).max(300),
  icon: z.string().trim().min(2).max(40),
  accent: z.enum(['danger', 'warning', 'info', 'success']),
  do_now: z.array(z.string().trim().min(3).max(300)).min(1).max(10),
  avoid: z.array(z.string().trim().min(3).max(300)).min(1).max(10),
  phone_numbers: z.array(phoneSchema).min(1).max(5),
  sort_order: z.number().int().min(0).max(10000),
  is_active: z.boolean().optional(),
});
