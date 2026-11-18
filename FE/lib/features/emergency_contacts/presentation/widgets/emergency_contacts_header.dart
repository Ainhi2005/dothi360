import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_back_button.dart';

class EmergencyContactsHeader extends StatelessWidget {
  const EmergencyContactsHeader({
    super.key,
    this.location = 'Hà Nội',
    this.onLocationTap,
  });

  final String location;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.spacingSm,
        AppDimens.spacingXs,
        AppDimens.spacingMd,
        AppDimens.spacingSm,
      ),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: AppDimens.spacingXs),
          Expanded(
            child: Text(
              'Danh bạ khẩn cấp',
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          InkWell(
            onTap: onLocationTap,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingSm + 4,
                vertical: AppDimens.spacingXs + 1,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    location,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
