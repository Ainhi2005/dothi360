class IncidentUpdateModel {
  final String? status;
  final String? note;
  final DateTime createdAt;
  final List<String> mediaUrls;
  final int? progressPercent;
  final DateTime? estimatedCompletionAt;
  final String? blocker;

  const IncidentUpdateModel({
    this.status,
    this.note,
    required this.createdAt,
    this.mediaUrls = const [],
    this.progressPercent,
    this.estimatedCompletionAt,
    this.blocker,
  });

  factory IncidentUpdateModel.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json['media'] as List<dynamic>? ??
        json['media_urls'] as List<dynamic>? ??
        const [];
    final urls = mediaRaw
        .map((m) => m is Map ? m['file_url']?.toString() : m?.toString())
        .whereType<String>()
        .toList();

    return IncidentUpdateModel(
      status: json['new_status']?.toString(),
      note: json['note']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      mediaUrls: urls,
      progressPercent: int.tryParse('${json['progress_percent'] ?? ''}'),
      estimatedCompletionAt: DateTime.tryParse(
        json['estimated_completion_at']?.toString() ?? '',
      ),
      blocker: json['blocker']?.toString(),
    );
  }
}

class IncidentDetailModel {
  final String id;
  final String description;
  final String incidentTypeName;
  final String status;
  final String? priorityLevel;
  final double? priorityScore;
  final int severityLevel;
  final int reportCount;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final double? latitude;
  final double? longitude;
  final List<String> imageUrls;
  final List<String> officerImageUrls;
  final List<IncidentUpdateModel> updates;
  final String? departmentName;
  final Map<String, dynamic>? aiAnalysis;
  final bool isMine;
  final String? verificationNote;

  const IncidentDetailModel({
    required this.id,
    required this.description,
    required this.incidentTypeName,
    required this.status,
    required this.severityLevel,
    required this.reportCount,
    required this.createdAt,
    required this.imageUrls,
    this.officerImageUrls = const [],
    required this.updates,
    this.priorityLevel,
    this.priorityScore,
    this.resolvedAt,
    this.latitude,
    this.longitude,
    this.departmentName,
    this.aiAnalysis,
    this.isMine = false,
    this.verificationNote,
  });

  factory IncidentDetailModel.fromJson(Map<String, dynamic> json) {
    final type = json['incident_type'] as Map<String, dynamic>? ?? const {};
    final location = json['location'] as Map<String, dynamic>?;
    final coordinates = location?['coordinates'] as List<dynamic>?;
    final allMedia = json['media'] as List<dynamic>? ?? const [];
    final reportMedia = json['report_media'] as List<dynamic>? ?? allMedia;
    final officerMedia = json['officer_media'] as List<dynamic>? ?? const [];
    final updates = json['updates'] as List<dynamic>? ?? const [];
    final assignment = json['assignment'] as Map<String, dynamic>?;

    final parsedReportMedia = reportMedia
        .map((item) => (item as Map<String, dynamic>)['file_url']?.toString())
        .whereType<String>()
        .toList();

    final parsedOfficerMedia = officerMedia
        .map((item) => (item as Map<String, dynamic>)['file_url']?.toString())
        .whereType<String>()
        .toList();

    final parsedUpdates = updates
        .map((item) =>
            IncidentUpdateModel.fromJson(item as Map<String, dynamic>))
        .toList();

    String? parsedVerificationNote = json['verification_note']?.toString();
    if (parsedVerificationNote == null || parsedVerificationNote.isEmpty) {
      final resolvedUpdate =
          parsedUpdates.where((u) => u.status == 'RESOLVED').firstOrNull;
      parsedVerificationNote = resolvedUpdate?.note;
    }

    return IncidentDetailModel(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      incidentTypeName: type['name']?.toString() ?? 'Sự cố đô thị',
      status: json['status']?.toString() ?? 'PENDING_ASSIGNMENT',
      priorityLevel: json['priority_level']?.toString(),
      priorityScore: double.tryParse('${json['priority_score'] ?? ''}'),
      severityLevel: int.tryParse('${json['severity_level'] ?? 0}') ?? 0,
      reportCount: int.tryParse('${json['report_count'] ?? 1}') ?? 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      resolvedAt: DateTime.tryParse(json['resolved_at']?.toString() ?? ''),
      longitude: coordinates != null && coordinates.isNotEmpty
          ? double.tryParse('${coordinates[0]}')
          : null,
      latitude: coordinates != null && coordinates.length > 1
          ? double.tryParse('${coordinates[1]}')
          : null,
      imageUrls: parsedReportMedia,
      officerImageUrls: parsedOfficerMedia,
      updates: parsedUpdates,
      departmentName: assignment?['department_name']?.toString(),
      aiAnalysis: json['ai_analysis'] as Map<String, dynamic>?,
      isMine: json['is_mine'] == true,
      verificationNote: parsedVerificationNote,
    );
  }
}
