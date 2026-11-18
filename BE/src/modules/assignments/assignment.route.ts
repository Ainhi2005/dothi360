import { Router } from 'express';
import { 
  getAllAssignments, 
  getMyDepartmentAssignments, 
  getOfficerAssignment, 
  acceptAssignment, 
  rejectAssignment,
  reassign, 
  getOfficerDashboard, 
  getOfficerPerformance,
  approveAiSuggestion,
  assignOfficer,
  getCandidates
} from './assignment.controller';
import { validateBody } from '../../common/middlewares/validate.middleware';
import { reassignSchema, rejectAssignmentSchema } from './assignment.validation';
import { authenticate } from '../../common/middlewares/authenticate.middleware';
import { authorizeRole } from '../../common/middlewares/authorize.middleware';
import { ROLES } from '../../common/constants/roles';

const assignmentRouter = Router();

// Yêu cầu đăng nhập
assignmentRouter.use(authenticate);
assignmentRouter.get('/', authorizeRole(ROLES.ADMIN), getAllAssignments);
assignmentRouter.get('/officer-performance', authorizeRole(ROLES.ADMIN), getOfficerPerformance);
assignmentRouter.get('/candidates', authorizeRole(ROLES.ADMIN), getCandidates);

// Dành cho Cán bộ (OFFICER)
assignmentRouter.get('/officer-dashboard', authorizeRole(ROLES.OFFICER), getOfficerDashboard);
assignmentRouter.get('/department', authorizeRole(ROLES.OFFICER, ROLES.ADMIN), getMyDepartmentAssignments);
assignmentRouter.get('/:id', authorizeRole(ROLES.OFFICER), getOfficerAssignment);
assignmentRouter.post('/:id/accept', authorizeRole(ROLES.OFFICER), acceptAssignment);
assignmentRouter.post('/:id/reject', authorizeRole(ROLES.OFFICER), validateBody(rejectAssignmentSchema), rejectAssignment);

// Dành riêng cho Admin
assignmentRouter.post('/reassign', authorizeRole(ROLES.ADMIN), validateBody(reassignSchema), reassign);
assignmentRouter.post('/approve-suggestion', authorizeRole(ROLES.ADMIN), approveAiSuggestion);
assignmentRouter.post('/assign-officer', authorizeRole(ROLES.ADMIN), assignOfficer);

export default assignmentRouter;

