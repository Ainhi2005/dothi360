import { z } from 'zod';

export const createEmergencyContactSchema = z.object({
  name: z.string().trim().min(2, 'Tên đơn vị phải có ít nhất 2 ký tự').max(160),
  phone_number: z.string().trim().min(3, 'Số điện thoại phải có ít nhất 3 ký tự').max(50),
  category: z.string().trim().min(2).max(60).default('NATIONAL'),
  description: z.string().trim().min(5, 'Mô tả phải có ít nhất 5 ký tự').max(300),
  icon: z.string().trim().max(40).default('phone'),
  accent: z.enum(['primary', 'danger', 'warning', 'info', 'success']).default('primary'),
  is_hotline: z.boolean().default(false),
  sort_order: z.number().int().min(0).default(0),
  is_active: z.boolean().default(true),
  operating_hours: z.string().trim().max(60).default('24/7'),
});

export const updateEmergencyContactSchema = createEmergencyContactSchema.partial();
