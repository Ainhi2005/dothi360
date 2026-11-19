import { Router } from 'express';
import { getAll, getOne, create, update, updateMe, remove, resetPassword } from './user.controller';
import { validateBody } from '../../common/middlewares/validate.middleware';
import { createUserSchema, updateUserSchema, updateProfileSchema, resetUserPasswordSchema } from './user.validation';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { authorizeRole } from '../../common/middlewares/authorize.middleware';
import { ROLES } from '../../common/constants/roles';

const userRouter = Router();

// Toàn bộ route User yêu cầu đăng nhập (thực tế nên viết thêm authorize.middleware check ADMIN)
userRouter.use(authenticate);

userRouter.patch('/me', validateBody(updateProfileSchema), updateMe);
userRouter.use(authorizeRole(ROLES.ADMIN));
userRouter.get('/', getAll);
userRouter.get('/:id', getOne);
userRouter.patch('/:id/password', validateBody(resetUserPasswordSchema), resetPassword);
userRouter.post('/', validateBody(createUserSchema), create);
userRouter.put('/:id', validateBody(updateUserSchema), update);
userRouter.delete('/:id', remove);

export default userRouter;
