import { NextFunction, Request, Response } from 'express';
import { AdminDashboardService } from './admin-dashboard.service';
const service = new AdminDashboardService();
const send = (fn: (request: Request) => Promise<unknown>) => async (request: Request, response: Response, next: NextFunction) => {
  try { response.json({ success: true, data: await fn(request) }); } catch (error) { next(error); }
};
export const summary = send(() => service.summary());
export const trends = send(request => service.trends(Number(request.query.days) || 30));
export const workload = send(() => service.workload());
export const sla = send(request => service.sla(Number(request.query.hours) || 24));
export const hotspots = send(() => service.hotspots());
export const notifications = send(request => service.notifications(request.user.id, Number(request.query.page) || 1, Number(request.query.limit) || 30));
export const aiMetrics = send(() => service.aiMetrics());
export const aiConfusion = send(() => service.aiConfusion());
export const aiComparison = send(() => service.aiComparison());
export const aiSamplesCsv = async (_request:Request,response:Response,next:NextFunction)=>{try{response.setHeader('Content-Type','text/csv; charset=utf-8');response.setHeader('Content-Disposition','attachment; filename="ai-evaluation-samples.csv"');response.send('\uFEFF'+await service.aiSamplesCsv());}catch(error){next(error)}};
export const exportCsv = async (_request: Request, response: Response, next: NextFunction) => {
  try { response.setHeader('Content-Type', 'text/csv; charset=utf-8'); response.setHeader('Content-Disposition', 'attachment; filename="incidents.csv"'); response.send('\uFEFF' + await service.exportCsv()); } catch (error) { next(error); }
};
export const exportXlsx = async (_request: Request, response: Response, next: NextFunction) => {
  try {
    const buffer = await service.exportXlsx();
    response.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    response.setHeader('Content-Disposition', 'attachment; filename="Bao-cao-su-co.xlsx"');
    response.send(buffer);
  } catch (error) { next(error); }
};

