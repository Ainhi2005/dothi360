class UserProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? departmentName;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.departmentName,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['id']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString(),
        role: json['role']?.toString() ?? 'CITIZEN',
        departmentName:json['department_name']?.toString(),
      );
}
