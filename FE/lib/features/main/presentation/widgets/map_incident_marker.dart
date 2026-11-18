import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

class MapIncidentMarker extends StatelessWidget {
  const MapIncidentMarker({
    super.key,
    required this.status,
    this.priorityLevel,
    required this.onTap,
  });

  final String status;
  final String? priorityLevel;
  final VoidCallback onTap;

  Color get _color {
    switch (status) {
      case 'ASSIGNED':
      case 'ACCEPTED':
        return AppColors.mapAssigned;
      case 'IN_PROGRESS':
        return AppColors.mapInProgress;
      case 'PENDING_VERIFICATION':
        return AppColors.mapVerification;
      case 'RESOLVED':
        return AppColors.mapResolved;
      case 'REJECTED':
      case 'CANCELLED':
        return AppColors.mapClosed;
      default:
        return AppColors.mapPending;
    }
  }

  IconData get _icon {
    switch (status) {
      case 'ASSIGNED':
      case 'ACCEPTED':
        return Icons.person_pin_circle_outlined;
      case 'IN_PROGRESS':
        return Icons.construction_rounded;
      case 'PENDING_VERIFICATION':
        return Icons.fact_check_outlined;
      case 'RESOLVED':
        return Icons.check_rounded;
      case 'REJECTED':
      case 'CANCELLED':
        return Icons.close_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'ASSIGNED':
      case 'ACCEPTED':
        return 'Đã tiếp nhận';
      case 'IN_PROGRESS':
        return 'Đang xử lý';
      case 'PENDING_VERIFICATION':
        return 'Chờ nghiệm thu';
      case 'RESOLVED':
        return 'Hoàn thành';
      case 'REJECTED':
      case 'CANCELLED':
        return 'Đã đóng';
      default:
        return 'Chờ phân công';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Sự cố: $_statusLabel',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            width: AppDimens.mapMarkerSize,
            height: AppDimens.mapMarkerSize,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: _color.withValues(alpha: 0.28),
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              _icon,
              color: AppColors.surface,
              size: AppDimens.iconSizeBase,
            ),
          ),
        ),
      ),
    );
  }
}
