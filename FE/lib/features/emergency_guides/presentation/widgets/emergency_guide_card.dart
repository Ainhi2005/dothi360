import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_guide_model.dart';

class EmergencyGuideCard extends StatelessWidget {
  const EmergencyGuideCard({
    super.key,
    required this.guide,
    required this.onTap,
  });

  final EmergencyGuideModel guide;
  final VoidCallback onTap;

  (Color bg, Color iconColor, IconData icon) get _visualStyle {
    final code = guide.code.toUpperCase();
    if (code.contains('INJURY') || guide.icon == 'medical_services') {
      return (
        AppColors.categoryMedicalBg,
        AppColors.categoryMedical,
        Icons.add_rounded,
      );
    }
    if (code.contains('FLOOD') || guide.icon == 'flood') {
      return (
        AppColors.categoryFloodBg,
        AppColors.categoryFlood,
        Icons.waves_rounded,
      );
    }
    if (code.contains('POWER') || guide.icon == 'electric_bolt') {
      return (
        AppColors.categoryElectricBg,
        AppColors.categoryElectric,
        Icons.bolt_rounded,
      );
    }
    if (code.contains('TREE') || guide.icon == 'park') {
      return (
        AppColors.categoryTreeBg,
        AppColors.categoryTree,
        Icons.park_rounded,
      );
    }
    if (code.contains('GAS') || guide.icon == 'science') {
      return (
        AppColors.categoryChemicalBg,
        AppColors.categoryChemical,
        Icons.science_rounded,
      );
    }
    if (code.contains('TRAFFIC') || guide.icon == 'car_crash') {
      return (
        AppColors.categoryTrafficBg,
        AppColors.categoryTraffic,
        Icons.directions_car_rounded,
      );
    }
    if (code.contains('ELEVATOR') || guide.icon == 'elevator') {
      return (
        AppColors.categoryElevatorBg,
        AppColors.categoryElevator,
        Icons.view_in_ar_rounded,
      );
    }
    return (
      AppColors.categoryFireBg,
      AppColors.categoryFire,
      Icons.local_fire_department_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, iconColor, iconData) = _visualStyle;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd + 4),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd + 4),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            child: Row(
              children: [
                Container(
                  width: AppDimens.emergencyIconBoxSize,
                  height: AppDimens.emergencyIconBoxSize,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd + 2),
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: AppDimens.iconSizeLg - 4,
                  ),
                ),
                const SizedBox(width: AppDimens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guide.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.spacingXs),
                      Text(
                        guide.summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.spacingSm),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
