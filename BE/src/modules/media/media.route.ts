import { Router } from 'express';
import multer from 'multer';
import { removeOrphanUpload, uploadFile } from './media.controller';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { mediaFileFilter } from './media.validation';
import { uploadLimiter } from '../../common/middlewares/rate-limiters.middleware';

const mediaRouter = Router();

const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024, files: 1 },
  fileFilter: mediaFileFilter,
});

mediaRouter.post('/upload', uploadLimiter, authenticate, upload.single('file'), uploadFile);
mediaRouter.delete('/upload', uploadLimiter, authenticate, removeOrphanUpload);

export default mediaRouter;
