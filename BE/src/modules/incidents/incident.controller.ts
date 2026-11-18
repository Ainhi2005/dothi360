import { Request, Response, NextFunction } from 'express';
import { IncidentService } from './incident.service';

const incidentService = new IncidentService();

export const createReport = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await incidentService.createReport(req.user.id, req.body);
    res.status(201).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const analyzeReport = async (req: Request, res: Response, next: NextFunction) => {
  try { res.json({ success: true, data: await incidentService.analyzeReport(req.body) }); }
  catch (error) { next(error); }
};

export const getAllIncidents = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await incidentService.findAll(req.query);
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

export const getMyReports = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await incidentService.getMyReports(req.user.id);
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const getIncidentDetail = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await incidentService.findOneForViewer(String(req.params.id), req.user);
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const getIncidentsByBbox = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { minLng, minLat, maxLng, maxLat } = req.query;
    if (minLng === undefined || minLat === undefined || maxLng === undefined || maxLat === undefined) {
      return res.status(400).json({ success: false, message: 'Vui lòng cung cấp tọa độ Bounding Box' });
    }
    
    let xmin = Number(minLng);
    let ymin = Number(minLat);
    let xmax = Number(maxLng);
    let ymax = Number(maxLat);

    if (isNaN(xmin) || isNaN(ymin) || isNaN(xmax) || isNaN(ymax)) {
      return res.status(400).json({ success: false, message: 'Tọa độ Bounding Box không hợp lệ' });
    }

    if (xmin > xmax) [xmin, xmax] = [xmax, xmin];
    if (ymin > ymax) [ymin, ymax] = [ymax, ymin];

    const result = await incidentService.getByBoundingBox(xmin, ymin, xmax, ymax);
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const getManualReviewQueue = async (req: Request, res: Response, next: NextFunction) => {
  try { res.json({ success: true, ...(await incidentService.listManualReview(req.query)) }); } catch (error) { next(error); }
};

export const reviewIncidentReport = async (req: Request, res: Response, next: NextFunction) => {
  try { res.json({ success: true, data: await incidentService.reviewReport(String(req.params.reportId), req.user.id, req.body) }); } catch (error) { next(error); }
};

export const reanalyzeIncident = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await incidentService.reanalyzeIncident(String(req.params.id));
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const updateStatus = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await incidentService.updateStatus(
      String(req.params.id),
      req.user.id,
      req.user.role,
      req.user.department_id,
      req.body,
    );
    res.status(200).json({ success: true, message: 'Đã cập nhật trạng thái', data: result });
  } catch (error) {
    next(error);
  }
};

export const verifyIncident = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await incidentService.verifyIncident(
      String(req.params.id),
      req.user.id,
      req.body,
    );
    res.json({ success: true, message: req.body.decision === 'APPROVE' ? 'Đã nghiệm thu sự cố' : 'Đã yêu cầu xử lý lại', data: result });
  } catch (error) { next(error); }
};

export const addIncidentProgress = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await incidentService.addProgressUpdate(
      String(req.params.id),
      req.user.id,
      req.user.department_id,
      req.body,
    );
    res.status(201).json({ success: true, message: 'Đã ghi nhận tiến độ xử lý', data: result });
  } catch (error) { next(error); }
};

export const endorseIncident = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await incidentService.endorseIncident(req.user.id, String(req.params.id));
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

