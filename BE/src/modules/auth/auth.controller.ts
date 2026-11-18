import { Request, Response, NextFunction } from 'express';
import { AuthService } from './auth.service';
import { UserService } from '../users/user.service';
import { env } from '../../config/env';

const authService = new AuthService();
const userService = new UserService();
const cookieName='refresh_token';
const cookieOptions={httpOnly:true,secure:env.NODE_ENV==='production',sameSite:'strict' as const,path:'/api/v1/auth',maxAge:7*24*60*60*1000};
const cookieToken=(req:Request)=>req.headers.cookie?.split(';').map(x=>x.trim()).find(x=>x.startsWith(`${cookieName}=`))?.slice(cookieName.length+1);

export const register = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = await authService.register(req.body);
    res.status(201).json({ success: true, message: 'Đăng ký thành công', data: user });
  } catch (error) {
    next(error);
  }
};

export const login = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await authService.login(req.body);
    if(req.header('x-client-type')==='admin-web'){res.cookie(cookieName,result.refresh_token,cookieOptions);const{refresh_token:_,...safeResult}=result;res.status(200).json({success:true,message:'Đăng nhập thành công',data:safeResult});return;}
    res.status(200).json({ success: true, message: 'Đăng nhập thành công', data: result });
  } catch (error) {
    next(error);
  }
};

export const refresh = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const token=req.body?.refresh_token||cookieToken(req);if(!token)throw{statusCode:401,message:'Thiếu refresh token'};const result = await authService.refresh(token);
    if(cookieToken(req)){res.cookie(cookieName,result.refresh_token,cookieOptions);const{refresh_token:_,...safeResult}=result;res.status(200).json({success:true,message:'Refresh token thành công',data:safeResult});return;}
    res.status(200).json({ success: true, message: 'Refresh token thành công', data: result });
  } catch (error) {
    next(error);
  }
};

export const logout = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const token=req.body?.refresh_token||cookieToken(req);if(token)await authService.logout(token);res.clearCookie(cookieName,{...cookieOptions,maxAge:undefined});
    res.status(200).json({ success: true, message: 'Đăng xuất thành công' });
  } catch (error) {
    next(error);
  }
};

export const getMe = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = await userService.findOne(req.user.id);
    res.status(200).json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

export const changePassword = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await authService.changePassword(req.user.id, req.body.current_password, req.body.new_password);
    res.status(200).json({ success: true, message: 'Đổi mật khẩu thành công' });
  } catch (error) {
    next(error);
  }
};
