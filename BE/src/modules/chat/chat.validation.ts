import { z } from 'zod';

export const chatSchema = z.object({
  message: z.string().trim().min(1, 'Vui lòng nhập câu hỏi').max(2000, 'Câu hỏi tối đa 2000 ký tự'),
  history: z.array(z.object({
    role: z.enum(['user', 'assistant']),
    content: z.string().trim().min(1).max(2000),
  })).max(10).default([]),
});
export type ChatHistory = z.infer<typeof chatSchema>['history'];
