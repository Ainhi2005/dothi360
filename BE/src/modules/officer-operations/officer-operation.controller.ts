import { NextFunction, Request, Response } from 'express';
import { OfficerOperationService } from './officer-operation.service';

const s = new OfficerOperationService();

const send = (fn: (q: Request) => Promise<any>) => async (q: Request, r: Response, n: NextFunction) => {
  try {
    r.json({ success: true, data: await fn(q) });
  } catch (e) {
    n(e);
  }
};

export const checklist = send((q) => s.checklist(String(q.params.id), q.user.id, q.user.department_id));
export const saveChecklist = send((q) => s.saveChecklist(String(q.params.id), q.user.id, q.user.department_id, q.body.items));
export const templates = send((q) => s.templates(String(q.params.typeId)));
export const replaceTemplates = send((q) => s.replaceTemplates(String(q.params.typeId), q.body.items));
export const performance = send((q) => s.performance(q.user.id));
