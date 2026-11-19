import { z } from 'zod';
import { chatIntentIds } from './chat.catalog';

export const chatSchema = z.object({
  message: z.string().trim().min(1, 'Vui lòng nhập câu hỏi').max(2000, 'Câu hỏi tối đa 2000 ký tự'),
  suggestion_id: z.string().refine(value => chatIntentIds.includes(value as any), 'Câu hỏi gợi ý không hợp lệ').optional(),
  history: z.array(z.object({
    role: z.enum(['user', 'assistant']),
    content: z.string().trim().min(1).max(2000),
  })).max(10).default([]),
});
export type ChatHistory = z.infer<typeof chatSchema>['history'];
