import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_guide_model.dart';
import 'guide_step_card.dart';

class GuideDoNowSection extends StatelessWidget {
  const GuideDoNowSection({
    super.key,
    required this.steps,
  });

  final List<EmergencyStepModel> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.emergencySuccessBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(
          color: AppColors.emergencySuccessBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.homeGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppDimens.spacingSm + 2),
              Text(
                'Việc cần làm ngay',
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingSm + 2,
                  vertical: AppDimens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emergencySuccessBorder,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                ),
                child: Text(
                  'Theo thứ tự',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.emergencySuccessText,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingMd),
          ...steps.asMap().entries.map((entry) {
            final isLast = entry.key == steps.length - 1;
            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppDimens.spacingSm + 2,
              ),
              child: GuideStepCard(step: entry.value),
            );
          }),
        ],
      ),
    );
  }
}
