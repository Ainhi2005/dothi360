import { Request, Response, NextFunction } from 'express';
import { EmergencyContactService } from './emergency-contact.service';

const service = new EmergencyContactService();

export const getPublicEmergencyContacts = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await service.getPublicContacts({
      category: req.query.category as string,
      q: req.query.q as string,
    });
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getAdminEmergencyContacts = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await service.getAdminContacts({
      category: req.query.category as string,
      q: req.query.q as string,
    });
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const createEmergencyContact = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await service.create(req.body);
    res.status(201).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const updateEmergencyContact = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await service.update(String(req.params.id), req.body);
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const deleteEmergencyContact = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await service.delete(String(req.params.id));
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
