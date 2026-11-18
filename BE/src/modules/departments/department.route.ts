import { Router } from 'express';
import { getAll, getOne, create, update, remove, getCapabilities, setCapabilities } from './department.controller';
import { z } from 'zod';
import { validateBody } from '../../common/middlewares/validate.middleware';
import { createDepartmentSchema, updateDepartmentSchema } from './department.validation';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { authorizeRole } from '../../common/middlewares/authorize.middleware';
import { ROLES } from '../../common/constants/roles';

const departmentRouter = Router();

// Yêu cầu đăng nhập mới được thao tác với department
departmentRouter.use(authenticate);

departmentRouter.get('/', getAll);
departmentRouter.get('/:id', getOne);
departmentRouter.get('/:id/capabilities', getCapabilities);
departmentRouter.use(authorizeRole(ROLES.ADMIN));
departmentRouter.post('/', validateBody(createDepartmentSchema), create);
departmentRouter.put('/:id', validateBody(updateDepartmentSchema), update);
departmentRouter.delete('/:id', remove);
departmentRouter.put('/:id/capabilities', validateBody(z.object({incident_type_ids:z.array(z.uuid())})), setCapabilities);

export default departmentRouter;
