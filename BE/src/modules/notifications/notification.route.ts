import { Router } from 'express';
import { z } from 'zod';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { validateBody } from '../../common/middlewares/validate.middleware';
import {
  list,
  read,
  readAll,
  remove,
  removeAll,
  registerDevice,
  removeDevice,
} from './notification.controller';

const r = Router();
r.use(authenticate);

r.get('/', list);
r.patch('/read-all', readAll);
r.delete('/all', removeAll);

r.post(
  '/devices',
  validateBody(
    z.object({
      token: z.string().min(20),
      platform: z.enum(['ANDROID', 'IOS', 'WEB']),
    })
  ),
  registerDevice
);

r.delete(
  '/devices',
  validateBody(z.object({ token: z.string().min(20) })),
  removeDevice
);

r.delete('/:id', remove);
r.delete('/', removeAll);
r.patch('/:id/read', read);

export default r;
