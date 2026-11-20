import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class OfficerAiRecommendationCard extends StatelessWidget {
  const OfficerAiRecommendationCard(
      {required this.recommendation, required this.onApply, super.key});
  final String recommendation;
  final VoidCallback onApply;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimens.spacingSm),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: AppDimens.iconSizeSm,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimens.spacingXs),
                const Expanded(
                  child: Text(
                    'AI đề xuất biện pháp xử lý:',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onApply,
                  child: const Text(
                    'Áp dụng vào ghi chú',
                    style: AppTextStyles.linkText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spacingXs),
            Text(
              recommendation,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      );
}
