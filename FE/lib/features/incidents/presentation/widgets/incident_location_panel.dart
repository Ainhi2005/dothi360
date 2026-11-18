import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class IncidentLocationPanel extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  const IncidentLocationPanel(
      {super.key, required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    if (latitude == null || longitude == null) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Vị trí sự cố', style: AppTextStyles.titleMedium),
      const SizedBox(height: AppDimens.spacingSm),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(children: [
          const Icon(Icons.location_on, size: 44, color: AppColors.error),
          const SizedBox(height: AppDimens.spacingSm),
          Text('Tọa độ GPS',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppDimens.spacingXs),
          SelectableText(
            '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
            style: AppTextStyles.bodyLarge,
          ),
        ]),
      ),
    ]);
  }
}
