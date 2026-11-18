import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EmergencyContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String category;
  final String description;
  final String icon;
  final String accent;
  final bool isHotline;
  final int sortOrder;
  final bool isActive;
  final String operatingHours;

  const EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.category,
    required this.description,
    required this.icon,
    required this.accent,
    required this.isHotline,
    required this.sortOrder,
    required this.isActive,
    required this.operatingHours,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      category: json['category']?.toString() ?? 'NATIONAL',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'phone',
      accent: json['accent']?.toString() ?? 'primary',
      isHotline: json['is_hotline'] == true,
      sortOrder: int.tryParse('${json['sort_order'] ?? 0}') ?? 0,
      isActive: json['is_active'] != false,
      operatingHours: json['operating_hours']?.toString() ?? '24/7',
    );
  }

  String get categoryLabel {
    switch (category) {
      case 'NATIONAL':
        return 'Khẩn cấp quốc gia';
      case 'INFRASTRUCTURE':
        return 'Hạ tầng đô thị';
      case 'MEDICAL':
        return 'Y tế & Cấp cứu';
      case 'SECURITY':
        return 'An ninh trật tự';
      case 'TRAFFIC':
        return 'Cứu hộ giao thông';
      case 'RESCUE':
        return 'Cứu nạn cứu hộ';
      default:
        return 'Liên hệ khẩn cấp';
    }
  }

  Color get accentColor {
    switch (accent) {
      case 'danger':
        return AppColors.error;
      case 'warning':
        return AppColors.warning;
      case 'info':
        return AppColors.info;
      case 'success':
        return AppColors.success;
      case 'primary':
      default:
        return AppColors.primary;
    }
  }

  Color get accentBgColor {
    switch (accent) {
      case 'danger':
        return AppColors.errorLight;
      case 'warning':
        return AppColors.warningLight;
      case 'info':
        return AppColors.infoLight;
      case 'success':
        return AppColors.successLight;
      case 'primary':
      default:
        return AppColors.primaryLight;
    }
  }

  IconData get iconData {
    switch (icon) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'medical_services':
        return Icons.medical_services_outlined;
      case 'local_police':
        return Icons.local_police_outlined;
      case 'support_agent':
        return Icons.support_agent;
      case 'electric_bolt':
        return Icons.electric_bolt_outlined;
      case 'flood':
        return Icons.flood_outlined;
      case 'car_crash':
        return Icons.car_crash_outlined;
      case 'park':
        return Icons.park_outlined;
      case 'health_and_safety':
        return Icons.health_and_safety_outlined;
      case 'sos':
        return Icons.emergency_outlined;
      case 'family_restroom':
        return Icons.family_restroom_outlined;
      case 'traffic':
        return Icons.traffic_outlined;
      case 'phone':
      default:
        return Icons.phone_in_talk_outlined;
    }
  }
}
