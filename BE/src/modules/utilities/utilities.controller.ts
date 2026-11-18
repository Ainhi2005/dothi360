import { Request, Response, NextFunction } from 'express';
import { UtilitiesService } from './utilities.service';

const service = new UtilitiesService();

export const getFloodPoints = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await service.getFloodPoints({
      status: req.query.status as string | undefined,
    });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getWeatherAqi = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const lat = req.query.lat !== undefined ? Number(req.query.lat) : 21.0285;
    const lng = req.query.lng !== undefined ? Number(req.query.lng) : 105.8542;
    const data = await service.getWeatherAndAqi(
      isNaN(lat) ? 21.0285 : lat,
      isNaN(lng) ? 105.8542 : lng
    );
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getDepartmentsDirectory = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userLat = req.query.lat !== undefined ? Number(req.query.lat) : undefined;
    const userLng = req.query.lng !== undefined ? Number(req.query.lng) : undefined;
    const data = await service.getDepartmentsDirectory(
      userLat !== undefined && !isNaN(userLat) ? userLat : undefined,
      userLng !== undefined && !isNaN(userLng) ? userLng : undefined
    );
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getSummary = async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await service.getSummary();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
