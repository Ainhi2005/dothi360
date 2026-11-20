import { AppDataSource } from "../../../database/data-source";
import { IncidentAssignment } from "../assignment.entity";
import { Incident } from "../../incidents/incident.entity";
import { IncidentUpdate } from "../../incident-updates/incident-update.entity";

/** Các dependency dùng chung, được khởi tạo một lần cho mỗi facade. */
export class AssignmentServiceDependencies {
  readonly assignmentRepo = AppDataSource.getRepository(IncidentAssignment);
  readonly incidentRepo = AppDataSource.getRepository(Incident);
  readonly updateRepo = AppDataSource.getRepository(IncidentUpdate);
}
