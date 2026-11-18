/** Router tổng tại /api/v1, nơi gắn route của từng module nghiệp vụ. */
import { Router, Request, Response } from 'express';
import { AppDataSource } from '../database/data-source';

const router = Router();

import authRouter from '../modules/auth/auth.route';
import departmentRouter from '../modules/departments/department.route';
import userRouter from '../modules/users/user.route';
import mediaRouter from '../modules/media/media.route';
import chatRouter from '../modules/chat/chat.route';
import incidentRouter from '../modules/incidents/incident.route';
import assignmentRouter from '../modules/assignments/assignment.route';
import incidentTypeRouter from '../modules/incident-types/incident-type.route';
import areaRouter from '../modules/areas/area.route';
import notificationRouter from '../modules/notifications/notification.route';
import algorithmConfigRouter from '../modules/algorithm-configs/algorithm-config.route';
import auditLogRouter from '../modules/audit-logs/audit-log.route';
import adminRouter from '../modules/admin/admin-dashboard.route';
import emergencyGuideRouter from '../modules/emergency-guides/emergency-guide.route';
import emergencyContactRouter from '../modules/emergency-contacts/emergency-contact.route';
import interestedAreaRouter from '../modules/interested-areas/interested-area.route';
import utilityRouter from '../modules/utilities/utilities.route';
import officerOperationRouter from '../modules/officer-operations/officer-operation.route';
import feedbackRouter from '../modules/feedbacks/feedback.route';
import {metricsSnapshot}from'../common/middlewares/observability.middleware';import{openapi}from'../docs/openapi';

// GET /api/v1/health
router.get('/health', async (req: Request, res: Response) => {
  // Kiểm tra xem database có đang được kết nối không
  const isDbConnected = AppDataSource.isInitialized;

  let database='disconnected';if(isDbConnected){try{await AppDataSource.query('SELECT 1');database='connected'}catch{database='unhealthy'}}res.status(database==='connected'?200:503).json({
    success: true,
    data: {
      status: 'ok',
      database,uptime_seconds:Math.round(process.uptime()),timestamp:new Date().toISOString()
    }
  });
});
router.get('/metrics',(_q,res)=>res.json({success:true,data:metricsSnapshot()}));router.get('/openapi.json',(_q,res)=>res.json(openapi));

router.use('/auth', authRouter);
router.use('/departments', departmentRouter);
router.use('/users', userRouter);
router.use('/media', mediaRouter);
router.use('/chat', chatRouter);
router.use('/incidents', incidentRouter);
router.use('/assignments', assignmentRouter);
router.use('/incident-types', incidentTypeRouter);
router.use('/areas', areaRouter);
router.use('/notifications', notificationRouter);
router.use('/algorithm-configs', algorithmConfigRouter);
router.use('/audit-logs', auditLogRouter);
router.use('/admin', adminRouter);
router.use('/emergency-guides', emergencyGuideRouter);
router.use('/emergency-contacts', emergencyContactRouter);
router.use('/interested-areas', interestedAreaRouter);
router.use('/utilities', utilityRouter);
router.use('/officer-operations', officerOperationRouter);
router.use('/feedbacks', feedbackRouter);

export default router;
