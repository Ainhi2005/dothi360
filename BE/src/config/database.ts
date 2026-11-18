/** Chứa cấu hình kết nối PostgreSQL/PostGIS theo từng môi trường. */
import { DataSourceOptions } from 'typeorm';
import { env } from './env';
import { databaseConnection } from './database-connection';
import { User } from '../modules/users/user.entity';
import { RefreshToken } from '../modules/auth/refresh-token.entity';
import { Department } from '../modules/departments/department.entity';

import { IncidentType } from '../modules/incident-types/incident-type.entity';
import { Incident } from '../modules/incidents/incident.entity';
import { IncidentReport } from '../modules/incident-reports/incident-report.entity';
import { IncidentMedia } from '../modules/media/media.entity';
import { IncidentAssignment } from '../modules/assignments/assignment.entity';
import { IncidentUpdate } from '../modules/incident-updates/incident-update.entity';
import { Area } from '../modules/areas/area.entity';
import { AlgorithmConfig } from '../modules/algorithm-configs/algorithm-config.entity';
import { AuditLog } from '../modules/audit-logs/audit-log.entity';
import { Notification } from '../modules/notifications/notification.entity';
import { EmergencyGuide } from '../modules/emergency-guides/emergency-guide.entity';
import { EmergencyContact } from '../modules/emergency-contacts/emergency-contact.entity';
import { InterestedArea } from '../modules/interested-areas/interested-area.entity';
import { CitizenFeedback } from '../modules/feedbacks/citizen-feedback.entity';

// Tách riêng config để dễ tái sử dụng
export const dbConfig: DataSourceOptions = {
  type: 'postgres',
  ...databaseConnection(env),
  // CỰC KỲ QUAN TRỌNG: Không cho phép TypeORM tự động sửa bảng đã tạo bằng SQL
  synchronize: false,
  logging: env.NODE_ENV === 'development',
  entities: [User, RefreshToken, Department, IncidentType, Incident, IncidentReport, IncidentMedia, IncidentAssignment, IncidentUpdate, Area, AlgorithmConfig, AuditLog, Notification, EmergencyGuide, EmergencyContact, InterestedArea, CitizenFeedback],
  migrations: [__dirname + '/../database/migrations/*.{ts,js}'],
  subscribers: [],
};
