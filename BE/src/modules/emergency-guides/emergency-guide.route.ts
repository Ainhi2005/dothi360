import { Router } from 'express';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { authorizeRole } from '../../common/middlewares/authorize.middleware';
import { ROLES } from '../../common/constants/roles';
import { validateBody } from '../../common/middlewares/validate.middleware';
import { create, getPublic, listAdmin, listPublic, remove, update } from './emergency-guide.controller';
import { emergencyGuideSchema } from './emergency-guide.validation';

const router = Router();
router.get('/', listPublic);
router.get('/admin', authenticate, authorizeRole(ROLES.ADMIN), listAdmin);
router.get('/:id', getPublic);
router.post('/', authenticate, authorizeRole(ROLES.ADMIN), validateBody(emergencyGuideSchema), create);
router.put('/:id', authenticate, authorizeRole(ROLES.ADMIN), validateBody(emergencyGuideSchema.partial()), update);
router.delete('/:id', authenticate, authorizeRole(ROLES.ADMIN), remove);
export default router;
