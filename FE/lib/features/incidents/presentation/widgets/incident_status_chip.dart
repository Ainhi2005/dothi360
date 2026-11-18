import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/incident_status.dart';

class IncidentStatusChip extends StatelessWidget {
  final String status;

  const IncidentStatusChip({super.key, required this.status});

  String get _label => switch (status) {
        IncidentStatus.resolved => 'Hoàn thành',
        IncidentStatus.assigned => 'Đã phân công',
        IncidentStatus.inProgress ||
        IncidentStatus.pendingAssignment =>
          'Đang xử lý',
        IncidentStatus.pendingVerification => 'Chờ nghiệm thu',
        IncidentStatus.rejected => 'Đã từ chối',
        IncidentStatus.cancelled => 'Đã hủy',
        _ => IncidentStatus.label(status),
      };

  Widget _buildLeadingIcon(Color color) {
    return switch (status) {
      IncidentStatus.resolved => Icon(Icons.check, size: 12, color: color),
      IncidentStatus.assigned => Icon(Icons.schedule, size: 12, color: color),
      IncidentStatus.rejected ||
      IncidentStatus.cancelled =>
        Icon(Icons.close, size: 12, color: color),
      _ => Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
    };
  }

  Color get _color => switch (status) {
        IncidentStatus.resolved => AppColors.success,
        IncidentStatus.rejected || IncidentStatus.cancelled => AppColors.error,
        IncidentStatus.assigned => AppColors.warning,
        IncidentStatus.pendingVerification => AppColors.warning,
        _ => AppColors.info,
      };

  Color get _background => switch (status) {
        IncidentStatus.resolved => AppColors.successLight,
        IncidentStatus.rejected ||
        IncidentStatus.cancelled =>
          AppColors.errorLight,
        IncidentStatus.assigned => AppColors.warningLight,
        IncidentStatus.pendingVerification => AppColors.warningLight,
        _ => AppColors.infoLight,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingSm + 2,
        vertical: AppDimens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLeadingIcon(color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
