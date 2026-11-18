import { Router } from 'express';
import { z } from 'zod';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { authorizeRole } from '../../common/middlewares/authorize.middleware';
import { validateBody } from '../../common/middlewares/validate.middleware';
import { ROLES } from '../../common/constants/roles';
import * as c from './officer-operation.controller';

const r = Router();
r.use(authenticate);

const officer = authorizeRole(ROLES.OFFICER);
const admin = authorizeRole(ROLES.ADMIN);

r.get('/performance/me', officer, c.performance);

// Checklist
r.get('/incidents/:id/checklist', officer, c.checklist);
r.put(
  '/incidents/:id/checklist',
  officer,
  validateBody(
    z.object({
      items: z.array(
        z.object({
          id: z.uuid(),
          completed: z.boolean(),
          note: z.string().max(500).nullable().optional(),
        })
      ),
    })
  ),
  c.saveChecklist
);

r.get('/admin/checklists/:typeId', admin, c.templates);
r.put(
  '/admin/checklists/:typeId',
  admin,
  validateBody(
    z.object({
      items: z.array(
        z.object({
          title: z.string().min(2).max(250),
          description: z.string().max(1000).nullable().optional(),
          is_required: z.boolean().optional(),
        })
      ).max(30),
    })
  ),
  c.replaceTemplates
);

export default r;
