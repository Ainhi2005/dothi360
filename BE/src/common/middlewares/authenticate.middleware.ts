import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';

// Khai báo thêm thuộc tính user cho Express Request
declare global {
  namespace Express {
    interface Request {
      user?: any;
    }
  }
}

export const authenticate = (req: Request, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ success: false, message: 'Không tìm thấy Access Token' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET);
    req.user = decoded; // Lưu payload vào req.user (id, role, department_id)
    if(req.user.must_change_password&&!['/api/v1/auth/password','/api/v1/auth/me','/api/v1/auth/logout'].includes(req.originalUrl.split('?')[0])){res.status(428).json({success:false,message:'Bạn phải đổi mật khẩu trước khi tiếp tục',code:'PASSWORD_CHANGE_REQUIRED'});return;}
    next();
  } catch (error) {
    res.status(401).json({ success: false, message: 'Token không hợp lệ hoặc đã hết hạn' });
  }
};

export const authenticateOptional = (req: Request, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    next();
    return;
  }
  authenticate(req, res, next);
};
