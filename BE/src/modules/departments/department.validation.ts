import { z } from 'zod';

export const createDepartmentSchema = z.object({
  code: z.string().min(1, 'Mã đơn vị không được trống'),
  name: z.string().min(1, 'Tên đơn vị không được trống'),
  address: z.string().optional(),
  phone: z.string().optional(),
  email: z.string().email('Email không đúng định dạng').optional().or(z.literal('')),
  longitude: z.number().min(-180).max(180).optional(),
  latitude: z.number().min(-90).max(90).optional(),
});

export const updateDepartmentSchema = createDepartmentSchema.partial();
