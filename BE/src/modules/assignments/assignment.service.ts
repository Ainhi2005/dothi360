import { AssignmentQueryService } from "./services/assignment-query.service";
import { OfficerDashboardService } from "./services/officer-dashboard.service";
import { AssignmentResponseService } from "./services/assignment-response.service";
import { AssignmentDispatchService } from "./services/assignment-dispatch.service";
import { AssignmentServiceDependencies } from "./services/assignment-dependencies";

/** Điểm vào ổn định cho controller; nghiệp vụ nằm trong services theo từng luồng. */
export class AssignmentService {
  private readonly deps = new AssignmentServiceDependencies();
  private readonly query = new AssignmentQueryService(this.deps);
  private readonly dashboard = new OfficerDashboardService(this.deps);
  private readonly response = new AssignmentResponseService(this.deps);
  private readonly dispatch = new AssignmentDispatchService(this.deps);

  async getOfficerDashboard(departmentId: string, userId: string) {
    return this.dashboard.getOfficerDashboard(departmentId, userId);
  }

  async getOfficerPerformance() {
    return this.dashboard.getOfficerPerformance();
  }

  async getOfficerAssignment(id: string, departmentId: string, userId: string) {
    return this.query.getOfficerAssignment(id, departmentId, userId);
  }

  async getAllAssignments(query: any = {}) {
    return this.query.getAllAssignments(query);
  }

  async getDepartmentAssignments(
    departmentId: string,
    userId: string,
    scope: string,
  ) {
    return this.query.getDepartmentAssignments(departmentId, userId, scope);
  }

  async acceptAssignment(
    assignmentId: string,
    userId: string,
    departmentId: string,
  ) {
    return this.response.acceptAssignment(assignmentId, userId, departmentId);
  }

  async rejectAssignment(
    assignmentId: string,
    userId: string,
    departmentId: string,
    data: { reason_code: string; reason: string },
  ) {
    return this.response.rejectAssignment(
      assignmentId,
      userId,
      departmentId,
      data,
    );
  }

  async reassign(data: any, adminId: string) {
    return this.dispatch.reassign(data, adminId);
  }

  async approveAiSuggestion(incidentId: string, adminId: string) {
    return this.dispatch.approveAiSuggestion(incidentId, adminId);
  }

  async assignOfficer(
    data: {
      incident_id: string;
      department_id: string;
      officer_id?: string;
      reason?: string;
    },
    adminId: string,
  ) {
    return this.dispatch.assignOfficer(data, adminId);
  }

  async getCandidates(incidentId: string) {
    return this.query.getCandidates(incidentId);
  }
}
