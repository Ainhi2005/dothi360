import { Router } from 'express';
import { getNearbyIncidents } from './incident.controller';
import { createReport, analyzeReport, getAllIncidents, getMyReports, getIncidentDetail, getIncidentsByBbox, updateStatus, getManualReviewQueue, reviewIncidentReport, reanalyzeIncident, verifyIncident, addIncidentProgress, endorseIncident } from './incident.controller';
import { validateBody } from '../../common/middlewares/validate.middleware';
import { createIncidentReportSchema } from './incident.validation';
import { authenticate, authenticateOptional } from '../../common/middlewares/authenticate.middleware';
import { reportLimiter } from '../../common/middlewares/rate-limiters.middleware';
import { authorizeRole } from '../../common/middlewares/authorize.middleware';
import { ROLES } from '../../common/constants/roles';
import { updateIncidentStatusSchema, reviewIncidentReportSchema, analyzeIncidentSchema, verifyIncidentSchema, addIncidentProgressSchema } from './incident.validation';

const incidentRouter = Router();

// Lấy danh sách map bbox (Không cần login để xem trên bản đồ)
incidentRouter.get('/map/bbox', getIncidentsByBbox);
incidentRouter.get('/nearby', getNearbyIncidents);
// Danh sách chung
incidentRouter.get('/', getAllIncidents);
// Route cụ thể phải đứng trước /:id để không coi "me" là ID sự cố.
incidentRouter.get('/me/reports', authenticate, getMyReports);
incidentRouter.post('/analyze', reportLimiter, authenticate, validateBody(analyzeIncidentSchema), analyzeReport);
incidentRouter.get('/admin/manual-review', authenticate, authorizeRole(ROLES.ADMIN), getManualReviewQueue);
incidentRouter.patch('/admin/manual-review/:reportId', authenticate, authorizeRole(ROLES.ADMIN), validateBody(reviewIncidentReportSchema), reviewIncidentReport);
incidentRouter.patch('/:id/verification', authenticate, authorizeRole(ROLES.ADMIN), validateBody(verifyIncidentSchema), verifyIncident);
// Chi tiết
incidentRouter.get('/:id', authenticateOptional, getIncidentDetail);
incidentRouter.post('/:id/ai-analyze', authenticate, reanalyzeIncident);
incidentRouter.post('/:id/endorse', authenticate, endorseIncident);

incidentRouter.post('/', reportLimiter, authenticate, validateBody(createIncidentReportSchema), createReport);

// Cán bộ cập nhật trạng thái
incidentRouter.patch('/:id/status', authenticate, authorizeRole(ROLES.OFFICER, ROLES.ADMIN), validateBody(updateIncidentStatusSchema), updateStatus);
incidentRouter.post('/:id/progress', authenticate, authorizeRole(ROLES.OFFICER), validateBody(addIncidentProgressSchema), addIncidentProgress);

export default incidentRouter;

