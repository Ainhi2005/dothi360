import type { UploadedMedia } from "../incident-media";
import { IncidentServiceDependencies } from "./incident-dependencies";

/** Phân tích ảnh và phân tích lại hồ sơ. */
export class IncidentAnalysisService {
  constructor(private readonly deps: IncidentServiceDependencies) {}

  async analyzeReport(data: {
    description: string;
    media_urls: UploadedMedia[];
  }) {
    return this.deps.aiService.analyzeIncidentImages(
      data.media_urls.map((item) => item.url),
      data.description,
    );
  }

  async reanalyzeIncident(id: string) {
    const incident = await this.deps.incidentRepo.findOne({ where: { id } });
    if (!incident) throw { statusCode: 404, message: "Không tìm thấy sự cố" };

    const mediaList = await this.deps.mediaRepo.find({
      where: { incident_id: id },
      order: { created_at: "ASC" },
    });
    const imageUrls = mediaList.map((m) => m.file_url).filter(Boolean);
    if (!imageUrls.length) {
      throw {
        statusCode: 400,
        message: "Sự cố không có hình ảnh để AI phân tích",
      };
    }

    const aiAnalysis = await this.deps.aiService.analyzeIncidentImages(
      imageUrls,
      incident.description,
    );

    let report = await this.deps.reportRepo.findOne({
      where: { incident_id: id },
      order: { created_at: "DESC" },
    });
    if (report) {
      report.ai_analysis = aiAnalysis;
      await this.deps.reportRepo.save(report);
    }
    return aiAnalysis;
  }
}
