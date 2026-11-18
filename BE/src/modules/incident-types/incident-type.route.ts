import { Router } from 'express';
import { getAll, getOne, create, update, remove } from './incident-type.controller';
import { validateBody } from '../../common/middlewares/validate.middleware';
import { incidentTypeSchema } from './incident-type.validation';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { authorizeRole } from '../../common/middlewares/authorize.middleware';
import { ROLES } from '../../common/constants/roles';

const incidentTypeRouter = Router();

// Xem danh sách không cần login (để App Mobile lấy danh mục hiển thị)
incidentTypeRouter.get('/', getAll);
incidentTypeRouter.get('/:id', getOne);

// Quản trị viên mới được thao tác thêm sửa xóa
incidentTypeRouter.use(authenticate, authorizeRole(ROLES.ADMIN));
incidentTypeRouter.post('/', validateBody(incidentTypeSchema), create);
incidentTypeRouter.put('/:id', validateBody(incidentTypeSchema.partial()), update);
incidentTypeRouter.delete('/:id', remove);

export default incidentTypeRouter;
