import { NextFunction, Request, Response } from 'express';
import { NotificationService } from './notification.service';

const s = new NotificationService();

export const list = async (q: Request, r: Response, n: NextFunction) => {
  try {
    r.json({ success: true, ...await s.list(q.user.id, Number(q.query.page) || 1, Number(q.query.limit) || 50) });
  } catch (e) {
    n(e);
  }
};

export const read = async (q: Request, r: Response, n: NextFunction) => {
  try {
    await s.markRead(String(q.params.id), q.user.id);
    r.json({ success: true });
  } catch (e) {
    n(e);
  }
};

export const readAll = async (q: Request, r: Response, n: NextFunction) => {
  try {
    await s.markAllRead(q.user.id);
    r.json({ success: true });
  } catch (e) {
    n(e);
  }
};

export const remove = async (q: Request, r: Response, n: NextFunction) => {
  try {
    await s.remove(String(q.params.id), q.user.id);
    r.json({ success: true, message: 'Đã xóa thông báo' });
  } catch (e) {
    n(e);
  }
};

export const removeAll = async (q: Request, r: Response, n: NextFunction) => {
  try {
    await s.removeAll(q.user.id);
    r.json({ success: true, message: 'Đã xóa tất cả thông báo' });
  } catch (e) {
    n(e);
  }
};

export const registerDevice = async (q: Request, r: Response, n: NextFunction) => {
  try {
    await s.registerDevice(q.user.id, q.body.token, q.body.platform);
    r.json({ success: true });
  } catch (e) {
    n(e);
  }
};

export const removeDevice = async (q: Request, r: Response, n: NextFunction) => {
  try {
    await s.removeDevice(q.user.id, q.body.token);
    r.json({ success: true });
  } catch (e) {
    n(e);
  }
};
