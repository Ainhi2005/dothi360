import { Router } from 'express';
import { chatWithBot } from './chat.controller';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { chatLimiter } from '../../common/middlewares/rate-limiters.middleware';
import { validateBody } from '../../common/middlewares/validate.middleware';
import { chatSchema } from './chat.validation';

const chatRouter = Router();

// Phải đăng nhập mới được chat (để AI biết userId gọi Database)
chatRouter.post('/', chatLimiter, authenticate, validateBody(chatSchema), chatWithBot);

export default chatRouter;
