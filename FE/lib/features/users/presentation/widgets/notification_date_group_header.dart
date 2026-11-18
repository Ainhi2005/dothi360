import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

/// Tiêu đề phân đoạn thông báo ("Mới", "Trước đó") theo mẫu thiết kế
class NotificationDateGroupHeader extends StatelessWidget {
  const NotificationDateGroupHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.itemCount,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        AppDimens.spacingBase,
        AppDimens.spacingBase + 2,
        AppDimens.spacingBase,
        AppDimens.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tiêu đề phân đoạn: "Mới" / "Trước đó"
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),

          // Nút hành động bên phải: "Xem tất cả"
          if (actionText != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(AppDimens.radiusXs),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.info,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
