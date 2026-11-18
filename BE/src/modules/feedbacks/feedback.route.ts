import { Router } from 'express';
import { z } from 'zod';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { authorizeRole } from '../../common/middlewares/authorize.middleware';
import { validateBody } from '../../common/middlewares/validate.middleware';
import { ROLES } from '../../common/constants/roles';
import * as c from './feedback.controller';

const r = Router();
r.use(authenticate);

// Công dân / mọi người dùng đã đăng nhập
r.get('/', c.list);
r.get('/mine', c.getMine);
r.get('/:id', c.getDetail);

r.post(
  '/',
  validateBody(
    z.object({
      title: z.string().min(5).max(250),
      content: z.string().min(10).max(3000),
      category: z.enum(['TRAFFIC', 'GREENERY', 'LIGHTING', 'DRAINAGE', 'ENVIRONMENT', 'GENERAL']).optional(),
      location_name: z.string().max(255).optional(),
      latitude: z.number().min(-90).max(90).optional(),
      longitude: z.number().min(-180).max(180).optional(),
    })
  ),
  c.create
);

r.post('/:id/upvote', c.toggleUpvote);

// Admin phản hồi & duyệt
r.patch(
  '/:id/respond',
  authorizeRole(ROLES.ADMIN),
  validateBody(
    z.object({
      status: z.enum(['ACCEPTED', 'REJECTED']),
      response_note: z.string().min(5).max(2000),
    })
  ),
  c.respond
);

export default r;

