import { Request, Response, NextFunction } from 'express';

/**
 * Middleware kiểm tra quyền (Role-Based Access Control)
 * Phải được đặt SAU middleware `authenticate` (để có `req.user`)
 */
export const authorizeRole = (...allowedRoles: string[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Chưa đăng nhập' });
      return;
    }

    if (!allowedRoles.includes(req.user.role)) {
      res.status(403).json({ 
        success: false, 
        message: 'Bạn không có quyền thực hiện hành động này' 
      });
      return;
    }

    next();
  };
};
