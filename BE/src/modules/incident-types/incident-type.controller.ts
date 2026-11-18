import { Request, Response, NextFunction } from 'express';
import { IncidentTypeService } from './incident-type.service';

const typeService = new IncidentTypeService();

export const getAll = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await typeService.findAll();
    res.status(200).json({ success: true, data });
  } catch (error) { next(error); }
};

export const getOne = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await typeService.findOne(String(req.params.id));
    res.status(200).json({ success: true, data });
  } catch (error) { next(error); }
};

export const create = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await typeService.create(req.body);
    res.status(201).json({ success: true, message: 'Tạo thành công', data });
  } catch (error) { next(error); }
};

export const update = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await typeService.update(String(req.params.id), req.body);
    res.status(200).json({ success: true, message: 'Cập nhật thành công', data });
  } catch (error) { next(error); }
};

export const remove = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await typeService.remove(String(req.params.id));
    res.status(200).json({ success: true, message: 'Đã xóa loại sự cố' });
  } catch (error) { next(error); }
};
