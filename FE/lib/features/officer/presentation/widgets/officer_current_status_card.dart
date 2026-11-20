import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/incident_status.dart';

class OfficerCurrentStatusCard extends StatelessWidget {
  const OfficerCurrentStatusCard({required this.currentStatus, super.key});
  final String currentStatus;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.sync_alt, color: AppColors.primary),
            const SizedBox(width: AppDimens.spacingBase),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trạng thái hiện tại',
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: AppDimens.spacingXs),
                  Text(
                    IncidentStatus.label(currentStatus),
                    style: AppTextStyles.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
