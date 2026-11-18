import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Banner cảnh báo đô thị chuẩn mực hành chính (Civic Alert Banner)
class UrbanAlertBanner extends StatelessWidget {
  const UrbanAlertBanner({
    super.key,
    required this.title,
    required this.message,
    required this.onTap,
    this.isUrgent = false,
  });

  final String title;
  final String message;
  final VoidCallback onTap;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final bgColor = isUrgent ? AppColors.errorLight : AppColors.warningLight;
    final borderColor =
        isUrgent ? AppColors.errorBorder : AppColors.warningBorder;
    final accentColor = isUrgent ? AppColors.errorText : AppColors.warningText;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spacingBase),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(
                    isUrgent
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded,
                    color: accentColor,
                    size: AppDimens.iconSizeBase,
                  ),
                ),
                const SizedBox(width: AppDimens.spacingBase),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.spacingSm),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: AppDimens.iconSizeBase,
                  color: accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
