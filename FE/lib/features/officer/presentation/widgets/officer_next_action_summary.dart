import 'package:flutter/material.dart';
import '../../../../core/constants/incident_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class OfficerNextActionSummary extends StatelessWidget {
  const OfficerNextActionSummary(
      {required this.currentStatus,
      required this.nextStatus,
      required this.inProgressAction,
      super.key});
  final String currentStatus;
  final String nextStatus;
  final String inProgressAction;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        decoration: BoxDecoration(
          color: inProgressAction == 'verification'
              ? AppColors.warningLight
              : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              inProgressAction == 'verification'
                  ? Icons.fact_check_outlined
                  : currentStatus == IncidentStatus.inProgress
                      ? Icons.update
                      : Icons.play_circle_outline,
              color: inProgressAction == 'verification'
                  ? AppColors.warning
                  : AppColors.primary,
            ),
            const SizedBox(width: AppDimens.spacingBase),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bước tiếp theo', style: AppTextStyles.bodySmall),
                  const SizedBox(height: AppDimens.spacingXs),
                  Text(
                    currentStatus == IncidentStatus.inProgress &&
                            inProgressAction == 'progress'
                        ? 'Báo cáo tiến độ mới'
                        : IncidentStatus.actionLabel(nextStatus),
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: AppDimens.spacingXs),
                  Text(
                    currentStatus == IncidentStatus.inProgress &&
                            inProgressAction == 'progress'
                        ? 'Ghi lại công việc đã làm; trạng thái vẫn là Đang xử lý.'
                        : IncidentStatus.actionDescription(nextStatus),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
