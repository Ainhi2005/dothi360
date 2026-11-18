class IncidentStatus {
  static const pendingAssignment = 'PENDING_ASSIGNMENT';
  static const assigned = 'ASSIGNED';
  static const accepted = 'ACCEPTED';
  static const inProgress = 'IN_PROGRESS';
  static const pendingVerification = 'PENDING_VERIFICATION';
  static const resolved = 'RESOLVED';
  static const rejected = 'REJECTED';
  static const cancelled = 'CANCELLED';
  static const terminal = {resolved, rejected, cancelled};

  static List<String> officerNextStatuses(String current) => switch (current) {
        assigned => const [inProgress],
        accepted => const [inProgress],
        inProgress => const [pendingVerification],
        _ => const [],
      };

  static String actionLabel(String status) => switch (status) {
        inProgress => 'Bắt đầu xử lý',
        pendingVerification => 'Gửi nghiệm thu',
        _ => label(status),
      };

  static String actionDescription(String status) => switch (status) {
        inProgress =>
          'Xác nhận bạn đã đến hiện trường hoặc bắt đầu triển khai xử lý.',
        pendingVerification =>
          'Gửi kết quả và ảnh minh chứng để quản trị viên nghiệm thu.',
        _ => '',
      };

  static String label(String status) => switch (status) {
        pendingAssignment => 'Chờ phân công',
        assigned => 'Đã phân công',
        accepted => 'Đã tiếp nhận',
        inProgress => 'Đang xử lý',
        pendingVerification => 'Chờ nghiệm thu',
        resolved => 'Hoàn thành',
        rejected => 'Từ chối',
        cancelled => 'Đã hủy',
        _ => status,
      };

  const IncidentStatus._();
}
