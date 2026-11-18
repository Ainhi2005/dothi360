import 'package:flutter/material.dart';
import '../constants/incident_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

enum AppStatusBadgeVariant { filled, subtle, dotOnly }

/// Huy hiệu hiển thị trạng thái sự cố và phân công thống nhất (Civic Status Badge)
class AppStatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;
  final AppStatusBadgeVariant variant;
  final bool showDot;

  const AppStatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.variant = AppStatusBadgeVariant.subtle,
    this.showDot = true,
  });

  String get _resolvedLabel {
    if (customLabel != null) return customLabel!;
    return IncidentStatus.label(status);
  }

  Color get _baseColor => switch (status.toUpperCase()) {
        IncidentStatus.resolved => AppColors.success,
        IncidentStatus.accepted || IncidentStatus.inProgress => AppColors.info,
        IncidentStatus.pendingAssignment ||
        IncidentStatus.assigned ||
        IncidentStatus.pendingVerification =>
          AppColors.warning,
        IncidentStatus.rejected || IncidentStatus.cancelled => AppColors.error,
        _ => AppColors.textSecondary,
      };

  Color get _bgColor => switch (status.toUpperCase()) {
        IncidentStatus.resolved => AppColors.successLight,
        IncidentStatus.accepted ||
        IncidentStatus.inProgress =>
          AppColors.infoLight,
        IncidentStatus.pendingAssignment ||
        IncidentStatus.assigned ||
        IncidentStatus.pendingVerification =>
          AppColors.warningLight,
        IncidentStatus.rejected ||
        IncidentStatus.cancelled =>
          AppColors.errorLight,
        _ => AppColors.surfaceSubtle,
      };

  Color get _borderColor => switch (status.toUpperCase()) {
        IncidentStatus.resolved => AppColors.successBorder,
        IncidentStatus.accepted ||
        IncidentStatus.inProgress =>
          AppColors.infoBorder,
        IncidentStatus.pendingAssignment ||
        IncidentStatus.assigned ||
        IncidentStatus.pendingVerification =>
          AppColors.warningBorder,
        IncidentStatus.rejected ||
        IncidentStatus.cancelled =>
          AppColors.errorBorder,
        _ => AppColors.border,
      };

  Widget _buildLeadingIcon(Color color) {
    return switch (status.toUpperCase()) {
      IncidentStatus.resolved =>
        Icon(Icons.check_circle_rounded, size: 12, color: color),
      IncidentStatus.rejected ||
      IncidentStatus.cancelled =>
        Icon(Icons.cancel_rounded, size: 12, color: color),
      _ => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _baseColor;

    if (variant == AppStatusBadgeVariant.dotOnly) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimens.spacingXs + 2),
          Text(
            _resolvedLabel,
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingSm,
        vertical: AppDimens.spacing2Xs + 1,
      ),
      decoration: BoxDecoration(
        color: variant == AppStatusBadgeVariant.filled ? color : _bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        border: Border.all(
          color: variant == AppStatusBadgeVariant.filled ? color : _borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            _buildLeadingIcon(
                variant == AppStatusBadgeVariant.filled ? Colors.white : color),
            const SizedBox(width: AppDimens.spacingXs + 1),
          ],
          Text(
            _resolvedLabel,
            style: AppTextStyles.caption.copyWith(
              color: variant == AppStatusBadgeVariant.filled
                  ? Colors.white
                  : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
