class IncidentListItemModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final int reportCount;
  final DateTime createdAt;

  const IncidentListItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.reportCount,
    required this.createdAt,
  });

  factory IncidentListItemModel.fromJson(Map<String, dynamic> json) {
    final type = json['incident_type'] as Map<String, dynamic>? ?? const {};
    return IncidentListItemModel(
      id: json['id']?.toString() ?? '',
      title: type['name']?.toString() ?? 'Sự cố đô thị',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING_ASSIGNMENT',
      reportCount: int.tryParse('${json['report_count'] ?? 1}') ?? 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
