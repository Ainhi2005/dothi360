import { Router } from 'express';
import { chatWithBot } from './chat.controller';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { chatLimiter } from '../../common/middlewares/rate-limiters.middleware';

const chatRouter = Router();

// Phải đăng nhập mới được chat (để AI biết userId gọi Database)
chatRouter.post('/', chatLimiter, authenticate, chatWithBot);

export default chatRouter;
