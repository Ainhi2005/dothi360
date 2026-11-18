import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({
    super.key,
    required this.total,
    required this.resolved,
    this.totalLabel = 'Tổng phản ánh',
    this.resolvedLabel = 'Đã hoàn thành',
  });

  final int total;
  final int resolved;
  final String totalLabel;
  final String resolvedLabel;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.spacingBase),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ProfileStatItem(
                value: total,
                label: totalLabel,
              ),
            ),
            Container(
              width: 1,
              height: AppDimens.spacingXl,
              color: AppColors.divider,
            ),
            Expanded(
              child: _ProfileStatItem(
                value: resolved,
                label: resolvedLabel,
                highlighted: true,
              ),
            ),
          ],
        ),
      );
}

class _ProfileStatItem extends StatelessWidget {
  const _ProfileStatItem({
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  final int value;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: AppTextStyles.titleMedium.copyWith(
              color: highlighted ? AppColors.success : AppColors.homeNavy,
            ),
          ),
          const SizedBox(width: AppDimens.spacingSm),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      );
}
