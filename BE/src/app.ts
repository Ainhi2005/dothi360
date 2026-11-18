/** Khởi tạo Express app, đăng ký middleware và gắn router tổng của API. Không gọi listen trong file này để dễ kiểm thử. */
import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import apiRoutes from './routes';
import { corsOrigins, env } from './config/env';
import { mountAdmin } from './common/hosting/admin-static';
import { apiLimiter } from './common/middlewares/rate-limiters.middleware';
import { observe } from './common/middlewares/observability.middleware';
import swaggerUi from 'swagger-ui-express';
import { openapi } from './docs/openapi';

const app: Application = express();
app.set('trust proxy',1);app.use(observe);

// 1. Bảo mật HTTP headers
app.use(helmet());

// 2. Cho phép gọi API chéo miền (CORS)
app.use(cors({
  origin(origin, callback) {
    if (!origin || corsOrigins.includes(origin)) return callback(null, true);
    return callback(new Error('Origin không được CORS cho phép'));
  },
  credentials: true,
}));

// 3. Phân tích body JSON
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

import path from 'path';
// Phục vụ các file tĩnh trong thư mục uploads
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(openapi, {
  customSiteTitle: 'Đô thị 360 API',
  swaggerOptions: { persistAuthorization: true },
}));

// 4. Rate Limiting (Chống spam)
app.use(apiLimiter);

// 5. Mount Routes
app.use('/api/v1', apiRoutes);

if (env.SERVE_ADMIN === 'true') {
  mountAdmin(app, path.resolve(__dirname, '../admin-public'), env.NODE_ENV === 'production');
}

import { errorHandler } from './common/middlewares/error-handler.middleware';

// Xử lý route không tồn tại (404)
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found',
  });
});

// Error Handler - phải đặt ở dưới cùng
app.use(errorHandler);

export default app;
