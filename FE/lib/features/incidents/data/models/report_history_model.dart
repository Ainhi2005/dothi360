class ReportHistoryModel {
  final String reportId;
  final String incidentId;
  final String description;
  final String incidentTypeName;
  final String status;
  final String? priorityLevel;
  final double? priorityScore;
  final int reportCount;
  final DateTime createdAt;
  final List<String> imageUrls;

  const ReportHistoryModel({
    required this.reportId,
    required this.incidentId,
    required this.description,
    required this.incidentTypeName,
    required this.status,
    required this.createdAt,
    this.priorityLevel,
    this.priorityScore,
    this.reportCount = 1,
    this.imageUrls = const [],
  });

  factory ReportHistoryModel.fromJson(Map<String, dynamic> json) {
    final incident = json['incident'] as Map<String, dynamic>? ?? const {};
    final type = incident['incident_type'] as Map<String, dynamic>? ?? const {};
    final media = json['media'] as List<dynamic>? ?? const [];
    return ReportHistoryModel(
      reportId: json['id']?.toString() ?? '',
      incidentId: json['incident_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      incidentTypeName: type['name']?.toString() ?? 'Sự cố đô thị',
      status: incident['status']?.toString() ?? 'PENDING_ASSIGNMENT',
      priorityLevel: incident['priority_level']?.toString(),
      priorityScore: double.tryParse('${incident['priority_score'] ?? ''}'),
      reportCount: int.tryParse('${incident['report_count'] ?? 1}') ?? 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      imageUrls: media
          .map((item) => (item as Map<String, dynamic>)['file_url']?.toString())
          .whereType<String>()
          .toList(),
    );
  }
}
