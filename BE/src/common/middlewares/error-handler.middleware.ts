import { Request, Response, NextFunction } from 'express';
import multer from 'multer';

export const errorHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
  console.error(JSON.stringify({level:'error',event:'request_error',requestId:(req as any).requestId,message:err.message??String(err),stack:process.env.NODE_ENV==='development'?err.stack:undefined}));

  const statusCode = err.statusCode || (err instanceof multer.MulterError ? 400 : 500);
  const message = err.message || 'Internal Server Error';

  res.status(statusCode).json({
    success: false,
    message,
    request_id:(req as any).requestId,
  });
};
