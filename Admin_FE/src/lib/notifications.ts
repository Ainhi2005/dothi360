export type AdminNotification = {
  id?: string; type: string; title?: string; message?: string; is_read?: boolean;
  incident_id?: string; data?: { action_path?: string; action_label?: string };
};

export function notificationPath(item: AdminNotification): string | null {
  const path = item.data?.action_path;
  if (path && /^\/(incidents\/[^/?#]+|manual-review|citizen-feedbacks|assignments)(\?[^#]*)?$/.test(path)) return path;
  return item.incident_id ? `/incidents/${encodeURIComponent(item.incident_id)}` : null;
}

export function notificationCategory(type: string): string {
  const labels: Record<string, string> = {
    INCIDENT_PENDING_ASSIGNMENT: 'Chờ phân công',
    INCIDENT_PENDING_VERIFICATION: 'Chờ nghiệm thu',
    REPORT_PENDING_REVIEW: 'Cần kiểm duyệt',
    ASSIGNMENT_REJECTED: 'Cần điều phối lại',
    FEEDBACK_PENDING_REVIEW: 'Góp ý mới',
    INCIDENT_BLOCKED: 'Báo khó khăn',
    INCIDENT_SLA_OVERDUE: 'Quá hạn xử lý',
  };
  return labels[type] ?? 'Thông báo hệ thống';
}

export function notificationAction(item: AdminNotification): string {
  return item.data?.action_label ?? (item.type === 'INCIDENT_PENDING_VERIFICATION' ? 'Mở nghiệm thu' : 'Mở hồ sơ');
}
