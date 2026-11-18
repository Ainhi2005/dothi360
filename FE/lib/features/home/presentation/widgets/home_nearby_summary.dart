import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class HomeNearbySummary extends StatelessWidget {
  const HomeNearbySummary({
    super.key,
    required this.activeCount,
    required this.onOpen,
  });

  final int activeCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khu vực gần bạn',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.homeNavy,
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.spacingMd),
                child: Row(
                  children: [
                    Container(
                      width: AppDimens.spacingXxl,
                      height: AppDimens.spacingXxl,
                      decoration: BoxDecoration(
                        color: AppColors.homeMint,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimens.spacingXs),
                        child: Image.asset(
                          AppAssets.interestedArea,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeCount == 0
                                ? 'Khu vực chưa có sự cố mới'
                                : '$activeCount sự cố đang được theo dõi',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.homeNavy,
                            ),
                          ),
                          const SizedBox(height: AppDimens.spacingXs),
                          Text(
                            'Mở bản đồ để xem vị trí và tình trạng xử lý.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}
