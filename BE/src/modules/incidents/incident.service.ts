import type { UploadedMedia } from "./incident-media";
import { IncidentViewer } from "./incident.policy";

import { IncidentQueryService } from "./services/incident-query.service";
import { IncidentAnalysisService } from "./services/incident-analysis.service";
import { IncidentReviewService } from "./services/incident-review.service";
import { IncidentReportService } from "./services/incident-report.service";
import { IncidentProgressService } from "./services/incident-progress.service";
import { IncidentVerificationService } from "./services/incident-verification.service";
import { IncidentServiceDependencies } from "./services/incident-dependencies";

/** Điểm vào ổn định cho controller; nghiệp vụ nằm trong services theo từng luồng. */
export class IncidentService {
  private readonly deps = new IncidentServiceDependencies();
  private readonly query = new IncidentQueryService(this.deps);
  private readonly analysis = new IncidentAnalysisService(this.deps);
  private readonly review = new IncidentReviewService(this.deps);
  private readonly report = new IncidentReportService(this.deps);
  private readonly progress = new IncidentProgressService(this.deps, {
    findOne: (id) => this.findOne(id),
  });
  private readonly verification = new IncidentVerificationService(this.deps, {
    findOne: (id) => this.findOne(id),
  });

  async analyzeReport(data: {
    description: string;
    media_urls: UploadedMedia[];
  }) {
    return this.analysis.analyzeReport(data);
  }

  async listManualReview(query: { page?: unknown; limit?: unknown }) {
    return this.review.listManualReview(query);
  }

  async reviewReport(
    reportId: string,
    reviewerId: string,
    data: {
      decision: "APPROVE" | "REJECT";
      incident_type_id?: string;
      note: string;
    },
  ) {
    return this.review.reviewReport(reportId, reviewerId, data);
  }

  async createReport(reporterId: string, data: any) {
    return this.report.createReport(reporterId, data);
  }

  async findAll(query: any) {
    return this.query.findAll(query);
  }

  async findNearby(latitude: number, longitude: number, radiusM?: number) {
    return this.query.findNearby(latitude, longitude, radiusM);
  }

  async findOne(id: string) {
    return this.query.findOne(id);
  }

  async reanalyzeIncident(id: string) {
    return this.analysis.reanalyzeIncident(id);
  }

  async findOneForViewer(id: string, viewer?: IncidentViewer) {
    return this.query.findOneForViewer(id, viewer);
  }

  async getMyReports(userId: string) {
    return this.query.getMyReports(userId);
  }

  async getByBoundingBox(
    minLng: number,
    minLat: number,
    maxLng: number,
    maxLat: number,
  ) {
    return this.query.getByBoundingBox(minLng, minLat, maxLng, maxLat);
  }

  async updateStatus(
    id: string,
    userId: string,
    role: string,
    departmentId: string | null,
    data: any,
  ) {
    return this.progress.updateStatus(id, userId, role, departmentId, data);
  }

  async verifyIncident(
    id: string,
    adminId: string,
    data: { decision: "APPROVE" | "REWORK"; note: string },
  ) {
    return this.verification.verifyIncident(id, adminId, data);
  }

  async addProgressUpdate(
    id: string,
    officerId: string,
    departmentId: string | null,
    data: {
      note: string;
      media_urls?: Array<string | UploadedMedia>;
      progress_percent: number;
      estimated_completion_at?: string;
      blocker?: string;
      visibility: "PUBLIC" | "INTERNAL";
    },
  ) {
    return this.progress.addProgressUpdate(id, officerId, departmentId, data);
  }

  async endorseIncident(userId: string, incidentId: string) {
    return this.report.endorseIncident(userId, incidentId);
  }
}
