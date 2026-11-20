import { api } from "../../lib/api";
import type { AssignOfficerRequest } from "./assignment.types";

export const assignmentApi = {
  list: () => api.get("/assignments"),
  departments: () => api.get("/departments"),
  candidates: (incidentId: string) =>
    api.get("/assignments/candidates", { params: { incident_id: incidentId } }),
  approveSuggestion: (incidentId: string) =>
    api.post("/assignments/approve-suggestion", { incident_id: incidentId }),
  assignOfficer: (data: AssignOfficerRequest) =>
    api.post("/assignments/assign-officer", data),
};
