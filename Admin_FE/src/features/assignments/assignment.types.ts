export interface CandidateOfficer {
  id: string;
  full_name: string;
  email: string;
  phone?: string;
  department_id: string;
  department_name: string;
  active_workload: number;
}

export interface AssignOfficerRequest {
  incident_id: string;
  department_id: string;
  officer_id?: string;
  reason?: string;
}
