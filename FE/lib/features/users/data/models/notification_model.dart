class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.type,
    this.incidentId,
    this.assignmentId,
    this.feedbackId,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? type;
  final String? incidentId;
  final String? assignmentId;
  final String? feedbackId;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: '${json['id']}',
        title: '${json['title'] ?? ''}',
        message: '${json['message'] ?? ''}',
        createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ??
            DateTime.now(),
        isRead: json['is_read'] == true,
        type: json['type']?.toString(),
        incidentId: json['incident_id']?.toString() ??
            json['data']?['incident_id']?.toString(),
        assignmentId: json['data']?['assignment_id']?.toString(),
        feedbackId: json['data']?['feedback_id']?.toString(),
      );

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? type,
    String? incidentId,
    String? assignmentId,
    String? feedbackId,
  }) =>
      NotificationModel(
        id: id ?? this.id,
        title: title ?? this.title,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
        isRead: isRead ?? this.isRead,
        type: type ?? this.type,
        incidentId: incidentId ?? this.incidentId,
        assignmentId: assignmentId ?? this.assignmentId,
        feedbackId: feedbackId ?? this.feedbackId,
      );

  String get formattedTime {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Định dạng thời gian ngắn gọn chuẩn mẫu thông báo:
  /// - Dưới 1h: "X phút trước"
  /// - Trong ngày: "X giờ trước" (VD: 11 giờ trước)
  /// - Hôm qua: "Hôm qua lúc HH:mm" (VD: Hôm qua lúc 23:55)
  /// - Xa hơn: "dd/MM/yyyy" (VD: 30/10/2026)
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inSeconds < 60) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24 && now.day == createdAt.day) {
      return '${diff.inHours} giờ trước';
    } else {
      final today = DateTime(now.year, now.month, now.day);
      final itemDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final dayDiff = today.difference(itemDay).inDays;
      final h = createdAt.hour.toString().padLeft(2, '0');
      final m = createdAt.minute.toString().padLeft(2, '0');
      if (dayDiff == 1) {
        return 'Hôm qua lúc $h:$m';
      } else {
        final d = createdAt.day.toString().padLeft(2, '0');
        final mo = createdAt.month.toString().padLeft(2, '0');
        return '$d/$mo/${createdAt.year}';
      }
    }
  }

  /// Thông báo mới: tạo trong vòng 24 giờ hoặc chưa đọc
  bool get isNew {
    final diff = DateTime.now().difference(createdAt);
    return diff.inHours < 24 || !isRead;
  }

  String get dateGroupLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) {
      return 'Hôm nay';
    } else if (diffDays == 1) {
      return 'Hôm qua';
    } else {
      final d = createdAt.day.toString().padLeft(2, '0');
      final m = createdAt.month.toString().padLeft(2, '0');
      return 'Ngày $d/$m/${createdAt.year}';
    }
  }
}
