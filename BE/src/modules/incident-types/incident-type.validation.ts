import { z } from 'zod';

export const incidentTypeSchema = z.object({
  code: z.string().min(2),
  name: z.string().min(2),
  description: z.string().optional(),
  type_priority_level: z.number().min(1).max(5).optional(),
  default_severity: z.number().min(1).max(5).optional(),
  is_active: z.boolean().optional(),
});
