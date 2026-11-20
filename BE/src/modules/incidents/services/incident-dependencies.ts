import { AppDataSource } from "../../../database/data-source";
import { Incident } from "../incident.entity";
import { IncidentReport } from "../../incident-reports/incident-report.entity";
import { IncidentMedia } from "../../media/media.entity";
import { IncidentType } from "../../incident-types/incident-type.entity";
import { IncidentAssignment } from "../../assignments/assignment.entity";
import { IncidentUpdate } from "../../incident-updates/incident-update.entity";

import { DuplicateDetectionService } from "../../../algorithms/duplicate-detection/duplicate-detection.service";
import { DepartmentAssignmentService } from "../../../algorithms/department-assignment/department-assignment.service";
import { PriorityScoringService } from "../../../algorithms/priority-scoring/priority-scoring.service";
import { AiService } from "../../../common/services/ai.service";

import { NotificationService } from "../../notifications/notification.service";
import { AuditLogService } from "../../audit-logs/audit-log.service";

/** Các dependency dùng chung, được khởi tạo một lần cho mỗi facade. */
export class IncidentServiceDependencies {
  readonly incidentRepo = AppDataSource.getRepository(Incident);
  readonly reportRepo = AppDataSource.getRepository(IncidentReport);
  readonly mediaRepo = AppDataSource.getRepository(IncidentMedia);
  readonly typeRepo = AppDataSource.getRepository(IncidentType);
  readonly assignmentRepo = AppDataSource.getRepository(IncidentAssignment);
  readonly updateRepo = AppDataSource.getRepository(IncidentUpdate);
  readonly duplicateService = new DuplicateDetectionService();
  readonly assignmentService = new DepartmentAssignmentService();
  readonly scoringService = new PriorityScoringService();
  readonly aiService = new AiService();
  readonly notificationService = new NotificationService();
  readonly auditLogService = new AuditLogService();
}
