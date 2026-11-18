class OfficerAssignmentModel {
  const OfficerAssignmentModel({
    required this.id,
    required this.incidentId,
    required this.description,
    required this.status,
    required this.incidentTypeName,
    required this.departmentName,
    required this.assignedAt,
    this.acceptedBy,
    this.acceptedAt,
    this.assignedOfficerId,
    this.endedAt,
    this.priorityScore,
    this.priorityLevel,
    this.distanceM,
    this.reason,
    this.latitude,
    this.longitude,
    this.address,
    this.reportCount = 1,
    this.aiAnalysis,
    this.mediaUrls = const [],
    this.coverUrl,
    this.incidentCreatedAt,
    this.slaDeadline,
    this.lastProgressAt,
    this.verificationAttempts = 0,
    this.reworkRequired = false,
    this.progressPercent,
    this.assignmentState = 'WAITING',
    this.rejectionCode,
    this.rejectionReason,
    this.rejectedAt,
  });

  final String id;
  final String incidentId;
  final String description;
  final String status;
  final String incidentTypeName;
  final String departmentName;
  final DateTime assignedAt;
  final String? acceptedBy;
  final DateTime? acceptedAt;
  final String? assignedOfficerId;
  final DateTime? endedAt;
  final double? priorityScore;
  final String? priorityLevel;
  final double? distanceM;
  final String? reason;
  final double? latitude;
  final double? longitude;
  final String? address;
  final int reportCount;
  final Map<String, dynamic>? aiAnalysis;
  final List<String> mediaUrls;
  final String? coverUrl;
  final DateTime? incidentCreatedAt;
  final DateTime? slaDeadline;
  final DateTime? lastProgressAt;
  final int verificationAttempts;
  final bool reworkRequired;
  final int? progressPercent;
  final String assignmentState;
  final String? rejectionCode;
  final String? rejectionReason;
  final DateTime? rejectedAt;

  bool get isOverdue =>
      slaDeadline != null &&
      DateTime.now().isAfter(slaDeadline!) &&
      !const {'RESOLVED', 'REJECTED', 'CANCELLED'}.contains(status);
  bool get isUrgent => priorityLevel == 'HIGH' || priorityLevel == 'EMERGENCY';

  bool get isWaiting =>
      assignmentState == 'WAITING' &&
      endedAt == null &&
      acceptedBy == null &&
      status == 'ASSIGNED';
  bool get isResolved =>
      const {'RESOLVED', 'REJECTED', 'CANCELLED'}.contains(status);
  bool get isAssignmentClosed => endedAt != null ||
      const {'REJECTED', 'REASSIGNED', 'COMPLETED'}.contains(assignmentState);
  bool get wasRejected => assignmentState == 'REJECTED';
  bool get wasReassigned => assignmentState == 'REASSIGNED';
  bool get wasCompleted => assignmentState == 'COMPLETED';
  bool get canAct => !isAssignmentClosed &&
      !const {'RESOLVED', 'REJECTED', 'CANCELLED'}.contains(status);

  String get assignmentLabel => switch (assignmentState) {
        'REJECTED' => 'Đã từ chối',
        'REASSIGNED' => 'Đã điều chuyển',
        'COMPLETED' => 'Hoàn thành',
        'ACTIVE' => status == 'PENDING_VERIFICATION'
            ? 'Chờ nghiệm thu'
            : 'Đang xử lý',
        _ => 'Chờ nhận',
      };

  factory OfficerAssignmentModel.fromJson(Map<String, dynamic> json) {
    double? number(dynamic value) => double.tryParse('${value ?? ''}');
    final mediaRaw = json['media'] as List<dynamic>? ??
        json['media_urls'] as List<dynamic>? ??
        const [];
    final parsedMedia = mediaRaw
        .map((m) => m is Map ? m['file_url']?.toString() : m?.toString())
        .whereType<String>()
        .toList();

    return OfficerAssignmentModel(
      id: json['id']?.toString() ?? '',
      incidentId: json['incident_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ASSIGNED',
      incidentTypeName:
          json['incident_type_name']?.toString() ?? 'Sự cố đô thị',
      departmentName: json['department_name']?.toString() ?? 'Đơn vị xử lý',
      assignedAt: DateTime.tryParse(json['assigned_at']?.toString() ?? '') ??
          DateTime.now(),
      acceptedBy: json['accepted_by']?.toString(),
      acceptedAt: DateTime.tryParse(json['accepted_at']?.toString() ?? ''),
      assignedOfficerId: json['assigned_officer_id']?.toString(),
      endedAt: DateTime.tryParse(json['ended_at']?.toString() ?? ''),
      priorityScore: number(json['priority_score']),
      priorityLevel: json['priority_level']?.toString(),
      distanceM: number(json['distance_m']),
      reason: json['reason']?.toString(),
      latitude: number(json['latitude']),
      longitude: number(json['longitude']),
      address: json['address']?.toString().trim().isNotEmpty == true
          ? json['address'].toString().trim()
          : null,
      reportCount: int.tryParse('${json['report_count'] ?? 1}') ?? 1,
      aiAnalysis: json['ai_analysis'] as Map<String, dynamic>?,
      mediaUrls: parsedMedia,
      coverUrl: json['cover_url']?.toString(),
      incidentCreatedAt: DateTime.tryParse(
        json['incident_created_at']?.toString() ?? '',
      ),
      slaDeadline: DateTime.tryParse(json['sla_deadline']?.toString() ?? ''),
      lastProgressAt:
          DateTime.tryParse(json['last_progress_at']?.toString() ?? ''),
      verificationAttempts:
          int.tryParse('${json['verification_attempts'] ?? 0}') ?? 0,
      reworkRequired: json['rework_required'] == true,
      progressPercent: int.tryParse('${json['progress_percent'] ?? ''}'),
      assignmentState: json['assignment_state']?.toString() ??
          (json['rejected_at'] != null
              ? 'REJECTED'
              : (json['ended_at'] != null
                  ? (json['status']?.toString() == 'RESOLVED'
                      ? 'COMPLETED'
                      : 'REASSIGNED')
                  : (json['accepted_by'] != null ? 'ACTIVE' : 'WAITING'))),
      rejectionCode: json['rejection_code']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      rejectedAt: DateTime.tryParse(json['rejected_at']?.toString() ?? ''),
    );
  }
}
