import { Request, Response, NextFunction } from 'express';
import { DepartmentService } from './department.service';

const departmentService = new DepartmentService();

export const getAll = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await departmentService.findAll();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getOne = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await departmentService.findOne(String(req.params.id));
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const create = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await departmentService.create(req.body);
    res.status(201).json({ success: true, message: 'Tạo đơn vị thành công', data });
  } catch (error) {
    next(error);
  }
};

export const update = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await departmentService.update(String(req.params.id), req.body);
    res.status(200).json({ success: true, message: 'Cập nhật đơn vị thành công', data });
  } catch (error) {
    next(error);
  }
};

export const remove = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await departmentService.delete(String(req.params.id));
    res.status(200).json({ success: true, message: 'Đã ngừng hoạt động đơn vị' });
  } catch (error) {
    next(error);
  }
};
export const getCapabilities=async(req:Request,res:Response,next:NextFunction)=>{try{res.json({success:true,data:await departmentService.getCapabilities(String(req.params.id))})}catch(e){next(e)}};
export const setCapabilities=async(req:Request,res:Response,next:NextFunction)=>{try{res.json({success:true,data:await departmentService.setCapabilities(String(req.params.id),req.body.incident_type_ids)})}catch(e){next(e)}};
