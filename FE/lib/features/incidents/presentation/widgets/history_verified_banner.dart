import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class HistoryVerifiedBanner extends StatelessWidget {
  const HistoryVerifiedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingMd,
        vertical: AppDimens.spacingSm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.searchBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd + 2),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.homeGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: AppColors.homeGreen,
            ),
          ),
          const SizedBox(width: AppDimens.spacingSm),
          Expanded(
            child: Text(
              'Thông tin được kiểm duyệt và chuyển thẳng tới trực ban đô thị.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
