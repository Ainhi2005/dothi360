export const INCIDENT_STATUS = {
  PENDING_ASSIGNMENT: 'PENDING_ASSIGNMENT',
  ASSIGNED: 'ASSIGNED',
  ACCEPTED: 'ACCEPTED',
  IN_PROGRESS: 'IN_PROGRESS',
  PENDING_VERIFICATION: 'PENDING_VERIFICATION',
  RESOLVED: 'RESOLVED',
  REJECTED: 'REJECTED',
  CANCELLED: 'CANCELLED',
} as const;

export type IncidentStatus = typeof INCIDENT_STATUS[keyof typeof INCIDENT_STATUS];

const transitions: Record<IncidentStatus, readonly IncidentStatus[]> = {
  PENDING_ASSIGNMENT: ['ASSIGNED', 'CANCELLED'],
  ASSIGNED: ['ACCEPTED', 'IN_PROGRESS', 'CANCELLED'],
  ACCEPTED: ['IN_PROGRESS', 'REJECTED', 'CANCELLED'],
  IN_PROGRESS: ['PENDING_VERIFICATION', 'REJECTED', 'CANCELLED'],
  PENDING_VERIFICATION: ['RESOLVED', 'IN_PROGRESS', 'CANCELLED'],
  RESOLVED: [],
  REJECTED: [],
  CANCELLED: [],
};

export function canTransitionIncident(from: string, to: string): boolean {
  return (transitions[from as IncidentStatus] ?? []).includes(to as IncidentStatus);
}

const officerTransitions: Partial<Record<IncidentStatus, readonly IncidentStatus[]>> = {
  ASSIGNED: ['IN_PROGRESS'],
  ACCEPTED: ['IN_PROGRESS'],
  IN_PROGRESS: ['PENDING_VERIFICATION'],
};

export function canOfficerTransitionIncident(from: string, to: string): boolean {
  return (officerTransitions[from as IncidentStatus] ?? []).includes(to as IncidentStatus);
}
