import { Request, Response, NextFunction } from 'express';
import { AssignmentService } from './assignment.service';

const assignmentService = new AssignmentService();

export const getOfficerDashboard = async (req: Request, res: Response, next: NextFunction) => {
  try {
    if (!req.user.department_id) return res.status(403).json({ success: false, message: 'Bạn chưa được gán đơn vị xử lý' });
    res.json({ success: true, data: await assignmentService.getOfficerDashboard(req.user.department_id, req.user.id) });
  } catch (error) { next(error); }
};

export const getOfficerPerformance = async (_req: Request, res: Response, next: NextFunction) => {
  try { res.json({ success: true, data: await assignmentService.getOfficerPerformance() }); }
  catch (error) { next(error); }
};

export const getAllAssignments = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await assignmentService.getAllAssignments(req.query);
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

export const getMyDepartmentAssignments = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const departmentId = req.user.department_id;
    if (!departmentId) {
      return res.status(403).json({ success: false, message: 'Bạn không thuộc đơn vị nào' });
    }
    const data = await assignmentService.getDepartmentAssignments(
      departmentId,
      req.user.id,
      String(req.query.scope ?? 'all'),
    );
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getOfficerAssignment = async (req: Request, res: Response, next: NextFunction) => {
  try {
    if (!req.user.department_id) return res.status(403).json({ success: false, message: 'Bạn không thuộc đơn vị nào' });
    res.json({ success: true, data: await assignmentService.getOfficerAssignment(String(req.params.id), req.user.department_id, req.user.id) });
  } catch (error) { next(error); }
};

export const acceptAssignment = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await assignmentService.acceptAssignment(
      String(req.params.id),
      req.user.id, 
      req.user.department_id
    );
    res.status(200).json({ success: true, message: 'Đã tiếp nhận sự cố', data });
  } catch (error) {
    next(error);
  }
};

export const rejectAssignment = async (req: Request, res: Response, next: NextFunction) => {
  try {
    if (!req.user.department_id) {
      return res.status(403).json({ success: false, message: 'Bạn chưa thuộc đơn vị xử lý' });
    }
    const data = await assignmentService.rejectAssignment(
      String(req.params.id),
      req.user.id,
      req.user.department_id,
      req.body,
    );
    res.status(200).json({
      success: true,
      message: 'Đã chuyển hồ sơ về hàng chờ điều phối lại',
      data,
    });
  } catch (error) { next(error); }
};

export const reassign = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await assignmentService.reassign(req.body, req.user.id);
    res.status(200).json({ success: true, message: 'Đã phân công lại thành công', data });
  } catch (error) {
    next(error);
  }
};

export const approveAiSuggestion = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { incident_id } = req.body;
    if (!incident_id) {
      return res.status(400).json({ success: false, message: 'Thiếu incident_id' });
    }
    const data = await assignmentService.approveAiSuggestion(incident_id, req.user.id);
    res.status(200).json({ success: true, message: 'Đã duyệt đề xuất phân công của AI thành công', data });
  } catch (error) {
    next(error);
  }
};

export const assignOfficer = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { incident_id, department_id, officer_id, reason } = req.body;
    if (!incident_id || !department_id) {
      return res.status(400).json({ success: false, message: 'Thiếu incident_id hoặc department_id' });
    }
    const data = await assignmentService.assignOfficer({ incident_id, department_id, officer_id, reason }, req.user.id);
    res.status(200).json({ success: true, message: 'Đã phân công cán bộ thành công', data });
  } catch (error) {
    next(error);
  }
};

export const getCandidates = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const incident_id = String(req.query.incident_id || req.params.incident_id || '');
    if (!incident_id) {
      return res.status(400).json({ success: false, message: 'Thiếu incident_id' });
    }
    const data = await assignmentService.getCandidates(incident_id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

