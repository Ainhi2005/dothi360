import { api } from "../../lib/api";

export const incidentApi = {
  detail: (id: string) => api.get(`/incidents/${id}`),
  analyze: (id: string) => api.post(`/incidents/${id}/ai-analyze`),
  verify: (id: string, decision: "APPROVE" | "REWORK", note: string) =>
    api.patch(`/incidents/${id}/verification`, { decision, note }),
};
