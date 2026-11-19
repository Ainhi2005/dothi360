import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import { AppDataSource } from '../../database/data-source';
import { User } from '../../modules/users/user.entity';
import { credentialVersion } from '../../modules/auth/credential-version';

// Khai báo thêm thuộc tính user cho Express Request
declare global {
  namespace Express {
    interface Request {
      user?: any;
    }
  }
}

export const authenticate = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ success: false, message: 'Không tìm thấy Access Token' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET);
    if (typeof decoded === 'string' || typeof decoded.id !== 'string') throw new jwt.JsonWebTokenError('Invalid payload');
    const user = await AppDataSource.getRepository(User).findOne({ where: { id: decoded.id } });
    if (!user?.is_active || decoded.credential_version !== credentialVersion(user.password_hash)) {
      res.status(401).json({ success: false, code: 'SESSION_REVOKED', message: 'Phiên đăng nhập đã hết hiệu lực. Vui lòng đăng nhập lại.' });
      return;
    }
    req.user = { ...decoded, role: user.role, department_id: user.department_id, must_change_password: user.must_change_password };
    if(req.user.must_change_password&&!['/api/v1/auth/password','/api/v1/auth/me','/api/v1/auth/logout'].includes(req.originalUrl.split('?')[0])){res.status(428).json({success:false,message:'Bạn phải đổi mật khẩu trước khi tiếp tục',code:'PASSWORD_CHANGE_REQUIRED'});return;}
    next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError || error instanceof jwt.TokenExpiredError) {
      res.status(401).json({ success: false, message: 'Token không hợp lệ hoặc đã hết hạn' });
    } else { next(error); }
  }
};

export const authenticateOptional = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    next();
    return;
  }
  await authenticate(req, res, next);
};
