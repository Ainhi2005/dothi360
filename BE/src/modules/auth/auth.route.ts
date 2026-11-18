import { Router } from 'express';
import { register, login, refresh, logout, getMe, changePassword } from './auth.controller';
import { validateBody } from '../../common/middlewares/validate.middleware';
import { registerSchema, loginSchema, refreshSchema, changePasswordSchema } from './auth.validation';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { loginLimiter } from '../../common/middlewares/rate-limiters.middleware';

const authRouter = Router();

authRouter.post('/register', validateBody(registerSchema), register);
authRouter.post('/login', loginLimiter, validateBody(loginSchema), login);
authRouter.post('/refresh', loginLimiter, refresh);
authRouter.post('/logout', logout);
authRouter.get('/me', authenticate, getMe);
authRouter.patch('/password', authenticate, validateBody(changePasswordSchema), changePassword);

export default authRouter;
