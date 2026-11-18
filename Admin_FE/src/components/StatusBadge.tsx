const labels: Record<string, string> = { PENDING_ASSIGNMENT: 'Chờ phân công', ASSIGNED: 'Đã phân công', ACCEPTED: 'Đã tiếp nhận', IN_PROGRESS: 'Đang xử lý', PENDING_VERIFICATION: 'Chờ nghiệm thu', RESOLVED: 'Hoàn thành', REJECTED: 'Từ chối', CANCELLED: 'Đã hủy' };
export function StatusBadge({ status }: { status: string }) {
  return <span className={`status-text status-${status.toLowerCase()}`}><i/>{labels[status] ?? status}</span>;
}
