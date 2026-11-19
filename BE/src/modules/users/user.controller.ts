import { Request, Response, NextFunction } from 'express';
import { UserService } from './user.service';

const userService = new UserService();

export const resetPassword = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await userService.resetPassword(String(req.params.id), req.user.id, req.body);
    res.json({ success: true, message: 'Đã đổi mật khẩu và thu hồi các phiên đăng nhập cũ', data });
  } catch (error) { next(error); }
};

export const getAll = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await userService.findAll(req.query);
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

export const getOne = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await userService.findOne(String(req.params.id));
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const create = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await userService.create(req.body);
    res.status(201).json({ success: true, message: 'Tạo người dùng thành công', data });
  } catch (error) {
    next(error);
  }
};

export const update = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await userService.update(String(req.params.id), req.body);
    res.status(200).json({ success: true, message: 'Cập nhật thành công', data });
  } catch (error) {
    next(error);
  }
};

export const updateMe = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await userService.updateProfile(req.user.id, req.body);
    res.status(200).json({ success: true, message: 'Đã lưu thông tin cá nhân', data });
  } catch (error) {
    next(error);
  }
};

export const remove = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await userService.delete(String(req.params.id));
    res.status(200).json({ success: true, message: 'Đã vô hiệu hóa người dùng' });
  } catch (error) {
    next(error);
  }
};
