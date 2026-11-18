import { z } from 'zod';

export const uploadedMediaSchema = z.object({
  url: z.url(),
  type: z.enum(['image/jpeg', 'image/png', 'image/webp', 'video/mp4']),
  size: z.number().int().positive().max(10 * 1024 * 1024),
  storage_key: z.string().min(1).max(500),
});

export const createIncidentReportSchema = z.object({
  incident_type_id: z.string().uuid('ID loại sự cố không hợp lệ').optional(),
  description: z.string().min(3, 'Mô tả cần ít nhất 3 ký tự'),
  longitude: z.number().min(-180).max(180, 'Kinh độ không hợp lệ'),
  latitude: z.number().min(-90).max(90, 'Vĩ độ không hợp lệ'),
  reported_address: z.string().trim().max(500).nullable().optional(),
  location_source: z.enum(['GPS', 'MAP', 'SEARCH']).default('GPS'),
  reported_severity: z.number().min(1).max(5).optional(),
  media_urls: z.array(z.union([z.url(), uploadedMediaSchema])).max(5).optional(),
  ai_analysis: z.record(z.string(), z.any()).optional(),
  ai_confirmation: z.object({
    accepted: z.literal(true),
    suggested_incident_type: z.string().max(200).nullable().optional(),
    suggested_severity: z.number().int().min(1).max(5).nullable().optional(),
    confirmed_incident_type_id: z.string().uuid(),
    confirmed_severity: z.number().int().min(1).max(5),
    suggested_summary: z.string().trim().min(5).max(500).nullable().optional(),
    confirmed_summary: z.string().trim().min(5).max(500),
    summary_edited: z.boolean().default(false),
    confirmed_at: z.iso.datetime(),
  }),
});

export const analyzeIncidentSchema = z.object({
  description: z.string().min(3, 'Mô tả cần ít nhất 3 ký tự').max(2000),
  media_urls: z.array(uploadedMediaSchema).min(1).max(5),
});

export const getIncidentsQuerySchema = z.object({
  page: z.string().optional().transform(v => v ? parseInt(v, 10) : 1),
  limit: z.string().optional().transform(v => v ? parseInt(v, 10) : 10),
  status: z.string().optional(),
  incident_type_id: z.string().uuid().optional(),
  priority: z.enum(['LOW', 'MEDIUM', 'HIGH', 'EMERGENCY']).optional(),
  q: z.string().trim().max(200).optional(),
  manual_review: z.enum(['true', 'false']).optional(),
});

export const updateIncidentStatusSchema = z.object({
  status: z.enum(['IN_PROGRESS', 'PENDING_VERIFICATION', 'RESOLVED', 'REJECTED', 'CANCELLED']),
  note: z.string().nullable().optional(),
  media_urls: z.array(z.union([z.url(), uploadedMediaSchema])).max(5).nullable().optional(),
}).superRefine((data, context) => {
  if (['PENDING_VERIFICATION', 'RESOLVED', 'REJECTED', 'CANCELLED'].includes(data.status) && !data.note?.trim()) {
    context.addIssue({ code: 'custom', message: 'Vui lòng nhập lý do hoặc kết quả xử lý', path: ['note'] });
  }
  if (data.status === 'PENDING_VERIFICATION' && !data.media_urls?.length) {
    context.addIssue({
      code: 'custom',
      message: 'Gửi nghiệm thu cần ghi chú và ít nhất một ảnh minh chứng',
      path: ['media_urls'],
    });
  }
});

export const verifyIncidentSchema = z.object({
  decision: z.enum(['APPROVE', 'REWORK']),
  note: z.string().trim().min(3).max(1000),
});

export const addIncidentProgressSchema = z.object({
  note: z.string().trim().min(3, 'Ghi chú xử lý phải có ít nhất 3 ký tự').max(2000, 'Ghi chú tối đa 2000 ký tự'),
  media_urls: z.array(z.union([z.url(), uploadedMediaSchema])).max(5, 'Tối đa 5 ảnh minh chứng').nullable().optional(),
  progress_percent: z.number().int().min(0, 'Mức độ hoàn thành từ 0% đến 99%').max(99, 'Mức độ hoàn thành từ 0% đến 99% (chọn Gửi nghiệm thu nếu đã hoàn tất 100%)'),
  estimated_completion_at: z.string().refine(val => !isNaN(Date.parse(val)), { message: 'Thời gian dự kiến không đúng định dạng' }).nullable().optional(),
  blocker: z.string().trim().max(1000, 'Mô tả khó khăn tối đa 1000 ký tự').nullable().optional(),
  visibility: z.enum(['PUBLIC', 'INTERNAL']).default('PUBLIC'),
});

export const reviewIncidentReportSchema = z.object({
  decision: z.enum(['APPROVE', 'REJECT']),
  incident_type_id: z.string().uuid().optional(),
  note: z.string().trim().min(3).max(1000),
}).superRefine((data, context) => {
  if (data.decision === 'APPROVE' && !data.incident_type_id) {
    context.addIssue({ code: 'custom', message: 'Phải chọn loại sự cố khi duyệt', path: ['incident_type_id'] });
  }
});
