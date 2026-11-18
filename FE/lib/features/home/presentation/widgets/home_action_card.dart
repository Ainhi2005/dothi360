import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class HomeActionCard extends StatelessWidget {
  const HomeActionCard({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.onTap,
    this.primary = false,
  });

  final String image;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < AppDimens.homeActionCardBreakpoint;
          final foreground = primary ? AppColors.surface : AppColors.homeNavy;
          final imageSize = compact
              ? AppDimens.homeActionCompactIconSize
              : AppDimens.homeActionIconSize;
          final text = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: AppTextStyles.titleMedium.copyWith(color: foreground),
              ),
              const SizedBox(height: AppDimens.spacingXs),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: AppTextStyles.bodySmall.copyWith(
                  color: primary ? AppColors.surface : AppColors.textSecondary,
                ),
              ),
            ],
          );
          return Material(
            color: primary ? AppColors.homeGreen : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.spacingMd),
                child: compact
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(image,
                              width: imageSize, height: imageSize),
                          const SizedBox(height: AppDimens.spacingSm),
                          Flexible(child: text),
                          const SizedBox(height: AppDimens.spacingXs),
                          Icon(Icons.arrow_forward,
                              color: primary
                                  ? AppColors.surface
                                  : AppColors.homeGreen),
                        ],
                      )
                    : Row(
                        children: [
                          Image.asset(image,
                              width: imageSize, height: imageSize),
                          const SizedBox(width: AppDimens.spacingMd),
                          Expanded(child: text),
                          Icon(Icons.arrow_forward,
                              color: primary
                                  ? AppColors.surface
                                  : AppColors.homeGreen),
                        ],
                      ),
              ),
            ),
          );
        },
      );
}
