import { z } from 'zod';

export const interestedAreaSchema = z.object({
  name: z.string().trim().min(2).max(80),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  radius_m: z.number().int().min(200).max(10000),
  notifications_enabled: z.boolean().optional(),
});

export const interestedAreaStatusSchema = z.object({ is_active: z.boolean() });
