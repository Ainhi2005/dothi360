class CitizenFeedbackModel {
  const CitizenFeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.content,
    required this.category,
    this.locationName,
    required this.upvotes,
    required this.status,
    this.adminResponse,
    this.responderName,
    this.respondedAt,
    required this.isUpvoted,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String title;
  final String content;
  final String category;
  final String? locationName;
  final int upvotes;
  final String status;
  final String? adminResponse;
  final String? responderName;
  final DateTime? respondedAt;
  final bool isUpvoted;
  final DateTime createdAt;

  factory CitizenFeedbackModel.fromJson(Map<String, dynamic> json) {
    return CitizenFeedbackModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Người dân',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? 'GENERAL',
      locationName: json['location_name']?.toString(),
      upvotes: int.tryParse(json['upvotes']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'PENDING',
      adminResponse: json['admin_response']?.toString(),
      responderName: json['responder_name']?.toString(),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
      isUpvoted: json['is_upvoted'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CitizenFeedbackModel copyWith({
    int? upvotes,
    bool? isUpvoted,
    String? status,
    String? adminResponse,
  }) {
    return CitizenFeedbackModel(
      id: id,
      userId: userId,
      userName: userName,
      title: title,
      content: content,
      category: category,
      locationName: locationName,
      upvotes: upvotes ?? this.upvotes,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      responderName: responderName,
      respondedAt: respondedAt,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      createdAt: createdAt,
    );
  }
}

