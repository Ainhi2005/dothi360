import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.onEditPressed,
    required this.fullName,
    required this.email,
    this.phone,
  });

  final VoidCallback onEditPressed;
  final String fullName;
  final String email;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final initial = fullName.trim().isEmpty
        ? 'U'
        : fullName.trim().split(RegExp(r'\s+')).last[0].toUpperCase();
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        child: Row(
          children: [
            CircleAvatar(
              radius: AppDimens.spacingXl,
              backgroundColor: AppColors.surface,
              child: Text(
                initial,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spacingXs),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.78),
                    ),
                  ),
                  if (phone?.isNotEmpty == true) ...[
                    const SizedBox(height: AppDimens.spacingXs),
                    Text(
                      phone!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.surface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton.filled(
              tooltip: 'Chỉnh sửa hồ sơ',
              onPressed: onEditPressed,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface.withValues(alpha: 0.16),
                foregroundColor: AppColors.surface,
              ),
              icon: const Icon(
                Icons.edit_outlined,
                size: AppDimens.iconSizeBase,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
