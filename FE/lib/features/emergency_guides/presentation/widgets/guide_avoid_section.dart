import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_guide_model.dart';
import 'guide_avoid_card.dart';

class GuideAvoidSection extends StatelessWidget {
  const GuideAvoidSection({
    super.key,
    required this.items,
  });

  final List<EmergencyAvoidModel> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
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
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.emergencyPillBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block_flipped,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppDimens.spacingSm + 2),
              Text(
                'Tuyệt đối không nên làm',
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emergencyAlertText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingMd),
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppDimens.spacingSm + 2,
              ),
              child: GuideAvoidCard(item: entry.value),
            );
          }),
        ],
      ),
    );
  }
}
