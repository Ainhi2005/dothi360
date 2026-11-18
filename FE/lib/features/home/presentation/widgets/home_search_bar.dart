import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Thanh tìm kiếm sự cố / địa bàn trang chủ (Civic Search Bar)
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.onTap,
    required this.onFilter,
  });

  final VoidCallback onTap;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spacingBase,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search,
                size: AppDimens.iconSizeBase,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimens.spacingBase),
              Expanded(
                child: Text(
                  'Tìm sự cố hoặc địa điểm...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              InkResponse(
                onTap: onFilter,
                radius: AppDimens.spacingMd,
                child: const Icon(
                  Icons.tune,
                  size: AppDimens.iconSizeBase,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
}
