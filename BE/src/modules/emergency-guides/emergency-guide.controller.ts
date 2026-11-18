import { NextFunction, Request, Response } from 'express';
import { EmergencyGuideService } from './emergency-guide.service';

const service = new EmergencyGuideService();
const actor = (req: Request) => String((req as Request & { user?: { id?: string } }).user?.id ?? '');

export const listPublic = async (_req: Request, res: Response, next: NextFunction) => {
  try { res.json({ success: true, data: await service.list(true) }); } catch (error) { next(error); }
};
export const getPublic = async (req: Request, res: Response, next: NextFunction) => {
  try { res.json({ success: true, data: await service.get(String(req.params.id)) }); } catch (error) { next(error); }
};
export const listAdmin = async (_req: Request, res: Response, next: NextFunction) => {
  try { res.json({ success: true, data: await service.list(false) }); } catch (error) { next(error); }
};
export const create = async (req: Request, res: Response, next: NextFunction) => {
  try { res.status(201).json({ success: true, data: await service.create(req.body, actor(req)), message: 'Đã tạo hướng dẫn' }); } catch (error) { next(error); }
};
export const update = async (req: Request, res: Response, next: NextFunction) => {
  try { res.json({ success: true, data: await service.update(String(req.params.id), req.body, actor(req)), message: 'Đã cập nhật hướng dẫn' }); } catch (error) { next(error); }
};
export const remove = async (req: Request, res: Response, next: NextFunction) => {
  try { await service.deactivate(String(req.params.id), actor(req)); res.json({ success: true, message: 'Đã tạm ẩn hướng dẫn' }); } catch (error) { next(error); }
};
