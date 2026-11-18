import { existsSync } from 'node:fs';
import path from 'node:path';
import express, { Application } from 'express';
import helmet from 'helmet';

/** Hosting only: API handlers, auth cookies and business services remain unchanged. */
export function mountAdmin(app: Application, directory: string, production: boolean): void {
  const index = path.join(directory, 'index.html');
  if (!existsSync(index)) throw new Error('Thiếu bản build Admin. Chạy node scripts/build-render.cjs từ thư mục gốc.');
  const router = express.Router();
  router.use((req, _res, next) => {
    if (!['GET', 'HEAD'].includes(req.method) || /^\/(api(?:\/|$)|api-docs(?:\/|$)|uploads(?:\/|$))/.test(req.path)) return next('router');
    next();
  });
  router.use(helmet.contentSecurityPolicy({ directives: {
    ...helmet.contentSecurityPolicy.getDefaultDirectives(),
    'img-src': ["'self'", 'data:', 'blob:', 'https:'],
    'connect-src': ["'self'", 'https:'],
    'font-src': ["'self'", 'data:', 'https:'],
    'worker-src': ["'self'", 'blob:'],
    'frame-ancestors': ["'none'"],
    'upgrade-insecure-requests': production ? [] : null,
  } }));
  router.use(express.static(directory, { index: false }));
  router.use((req, res, next) => {
    // Missing assets/API endpoints must remain 404, not receive the SPA HTML.
    if (path.extname(req.path) || req.path.startsWith('/assets/') || !req.accepts('html')) return next();
    res.setHeader('Cache-Control', 'no-cache');
    res.sendFile(index);
  });
  app.use(router);
}
