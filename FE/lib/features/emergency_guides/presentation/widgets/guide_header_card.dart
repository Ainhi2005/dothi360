import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_guide_model.dart';

class GuideHeaderCard extends StatelessWidget {
  const GuideHeaderCard({
    super.key,
    required this.guide,
  });

  final EmergencyGuideModel guide;

  IconData get _dangerIcon {
    final code = guide.code.toUpperCase();
    if (code.contains('INJURY')) return Icons.medical_services_rounded;
    if (code.contains('FLOOD')) return Icons.waves_rounded;
    if (code.contains('POWER')) return Icons.bolt_rounded;
    if (code.contains('TREE')) return Icons.park_rounded;
    if (code.contains('GAS')) return Icons.science_rounded;
    if (code.contains('TRAFFIC')) return Icons.car_crash_rounded;
    if (code.contains('ELEVATOR')) return Icons.view_in_ar_rounded;
    return Icons.local_fire_department_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingLg - 4),
      decoration: BoxDecoration(
        color: AppColors.emergencyAlertBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(
          color: AppColors.emergencyAlertBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingSm + 4,
                  vertical: AppDimens.spacingXs + 1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emergencyPillBg,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                ),
                child: Text(
                  '• ${guide.dangerLevel.toUpperCase()}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.categoryFire,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd + 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.categoryFire.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _dangerIcon,
                  color: Colors.white,
                  size: AppDimens.iconSizeMd + 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSm),
          Text(
            guide.title,
            style: AppTextStyles.headingSmall.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppDimens.spacingSm),
          Text(
            guide.summary,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
