import { Router } from 'express';
import {
  getPublicEmergencyContacts,
  getAdminEmergencyContacts,
  createEmergencyContact,
  updateEmergencyContact,
  deleteEmergencyContact,
} from './emergency-contact.controller';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { authorizeRole } from '../../common/middlewares/authorize.middleware';
import { ROLES } from '../../common/constants/roles';
import { validateBody } from '../../common/middlewares/validate.middleware';
import { createEmergencyContactSchema, updateEmergencyContactSchema } from './emergency-contact.validation';

const emergencyContactRouter = Router();

// Public endpoint for mobile users & web users
emergencyContactRouter.get('/', getPublicEmergencyContacts);

// Admin-only endpoints
emergencyContactRouter.get('/admin', authenticate, authorizeRole(ROLES.ADMIN), getAdminEmergencyContacts);
emergencyContactRouter.post('/', authenticate, authorizeRole(ROLES.ADMIN), validateBody(createEmergencyContactSchema), createEmergencyContact);
emergencyContactRouter.put('/:id', authenticate, authorizeRole(ROLES.ADMIN), validateBody(updateEmergencyContactSchema), updateEmergencyContact);
emergencyContactRouter.delete('/:id', authenticate, authorizeRole(ROLES.ADMIN), deleteEmergencyContact);

export default emergencyContactRouter;
