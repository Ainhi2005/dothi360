export interface IncidentViewer {
  id: string;
  role: string;
  department_id?: string | null;
}

export function canViewInternalIncidentData(
  viewer: IncidentViewer | undefined,
  reporterIds: readonly string[],
  assignedDepartmentIds: readonly string[],
): boolean {
  if (!viewer) return false;
  if (viewer.role === 'ADMIN') return true;
  if (viewer.role === 'CITIZEN') return reporterIds.includes(viewer.id);
  if (viewer.role === 'OFFICER') {
    return Boolean(viewer.department_id && assignedDepartmentIds.includes(viewer.department_id));
  }
  return false;
}
