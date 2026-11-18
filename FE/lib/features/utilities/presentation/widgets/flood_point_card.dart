import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../data/models/utility_models.dart';

class FloodPointCard extends StatelessWidget {
  const FloodPointCard({
    super.key,
    required this.point,
    required this.onTap,
  });

  final FloodPointModel point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isResolved = point.status == 'RESOLVED';
    final isDraining = point.status == 'DRAINING';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: point.coverUrl != null
                          ? AppCachedImage(
                              imageUrl: point.coverUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                              errorWidget: _buildFallbackIcon(),
                            )
                          : _buildFallbackIcon(),
                    ),
                  ),
                  const SizedBox(width: AppDimens.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.spacingSm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isResolved
                                    ? AppColors.successLight
                                    : isDraining
                                        ? AppColors.warningLight
                                        : AppColors.errorLight,
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                              child: Text(
                                point.statusLabel,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isResolved
                                      ? AppColors.success
                                      : isDraining
                                          ? AppColors.warning
                                          : AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${point.reportCount} phản ánh',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.spacingXs),
                        Text(
                          point.title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.homeNavy,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingMd,
                  vertical: AppDimens.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.categoryFloodBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.straighten,
                      size: AppDimens.iconSizeSm,
                      color: AppColors.categoryFlood,
                    ),
                    const SizedBox(width: AppDimens.spacingSm),
                    Expanded(
                      child: Text(
                        'Độ sâu ước tính: ~${point.estimatedDepthCm}cm (${point.depthDescription})',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.categoryFlood,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: AppColors.categoryFloodBg,
      child: const Center(
        child: Icon(
          Icons.water_drop_outlined,
          color: AppColors.categoryFlood,
          size: 28,
        ),
      ),
    );
  }
}
