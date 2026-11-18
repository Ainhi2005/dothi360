import { Request, Response, NextFunction } from 'express';
import { ZodError, ZodType } from 'zod';

// Nhận vào 1 schema của Zod, kiểm tra req.body. Nếu lỗi -> chặn luôn
export const validateBody = (schema: ZodType) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      req.body = schema.parse(req.body); // parse và loại bỏ các field rác
      next();
    } catch (error: any) {
      if (error instanceof ZodError || error.name === 'ZodError') {
        const issues = error.issues || error.errors || [];
        const detailMsg = issues.map((e: any) => e.message).filter(Boolean).join('; ');
        res.status(400).json({
          success: false,
          message: detailMsg || 'Dữ liệu không hợp lệ',
          errors: issues.map((e: any) => ({ field: e.path.join('.'), message: e.message }))
        });
        return;
      }
      next(error);
    }
  };
};
