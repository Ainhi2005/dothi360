import { Request, Response, NextFunction } from 'express';
import { FeedbackService } from './feedback.service';

const service = new FeedbackService();

export const list = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await service.list({
      page: Number(req.query.page) || 1,
      limit: Number(req.query.limit) || 20,
      category: req.query.category as string,
      status: req.query.status as string,
      sort: req.query.sort as any,
      userId: req.user?.id,
    });
    res.json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

export const getMine = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await service.getMine(
      req.user.id,
      Number(req.query.page) || 1,
      Number(req.query.limit) || 20
    );
    res.json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

export const getDetail = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await service.getDetail(String(req.params.id), req.user?.id);
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const create = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await service.create(req.user.id, req.body);
    res.status(201).json({
      success: true,
      message: 'Gửi góp ý thành công. Cảm ơn sáng kiến của bạn!',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

export const toggleUpvote = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await service.toggleUpvote(String(req.params.id), req.user.id);
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const respond = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await service.respond(String(req.params.id), req.user.id, req.body);
    res.json({
      success: true,
      message: 'Đã cập nhật phản hồi góp ý',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};
