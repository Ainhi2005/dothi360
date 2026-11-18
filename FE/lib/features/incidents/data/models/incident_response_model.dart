class IncidentResponseModel {
  final bool success;
  final String? message;
  final IncidentModel? incident;

  IncidentResponseModel({required this.success, this.message, this.incident});

  factory IncidentResponseModel.fromJson(Map<String, dynamic> json) {
    return IncidentResponseModel(
      success: json['success'] ?? false,
      message: json['data']?['message'],
      incident: json['data']?['incident'] != null
          ? IncidentModel.fromJson(json['data']['incident'])
          : null,
    );
  }
}

class IncidentModel {
  final String id;
  final String description;
  final int severityLevel;
  final String status;
  final String priorityLevel;

  IncidentModel({
    required this.id,
    required this.description,
    required this.severityLevel,
    required this.status,
    required this.priorityLevel,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      severityLevel: json['severity_level'] ?? 0,
      status: json['status'] ?? '',
      priorityLevel: json['priority_level'] ?? '',
    );
  }
}
