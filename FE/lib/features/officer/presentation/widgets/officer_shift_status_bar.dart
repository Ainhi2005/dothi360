import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class OfficerShiftStatusBar extends StatelessWidget {
  const OfficerShiftStatusBar({
    required this.departmentName,
    required this.isOnline,
    required this.pendingSyncCount,
    this.onSyncPressed,
    super.key,
  });

  final String departmentName;
  final bool isOnline;
  final int pendingSyncCount;
  final VoidCallback? onSyncPressed;

  String _formatToday() {
    final now = DateTime.now();
    return 'Ngày ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: AppDimens.iconSizeSm,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppDimens.spacingXs),
                    Expanded(
                      child: Text(
                        departmentName.trim().isNotEmpty
                            ? departmentName
                            : 'Đội xử lý sự cố hiện trường',
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.spacingXs),
                Text(
                  'Ca trực hiện tại · ${_formatToday()}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingSm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppColors.surfaceSubtle
                      : AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  border: Border.all(
                    color:
                        isOnline ? AppColors.divider : AppColors.warningBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? AppColors.primary : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? 'Trực tuyến' : 'Ngoại tuyến',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isOnline
                            ? AppColors.textPrimary
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              if (pendingSyncCount > 0) ...[
                const SizedBox(height: AppDimens.spacingXs),
                InkWell(
                  onTap: onSyncPressed,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sync_rounded,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$pendingSyncCount chờ đồng bộ',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
