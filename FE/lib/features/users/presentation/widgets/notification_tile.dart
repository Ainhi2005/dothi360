import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../data/models/notification_model.dart';

/// Thẻ thông báo dạng ngắn gọn theo mẫu thiết kế
/// - Hàng phẳng, icon tròn pastel bên trái
/// - Tiêu đề in đậm nối tiếp nội dung, tối đa 2 dòng
/// - Mốc thời gian tương đối ("11 giờ trước", "Hôm qua lúc 23:55")
/// - Chấm tròn xanh bên phải cho tin chưa đọc
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationModel item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  IconData _iconForType(String? type) {
    switch (type) {
      case 'AREA_WARNING':
        return Icons.warning_amber_rounded;
      case 'STATUS_RESOLVED':
        return Icons.check_circle_outline_rounded;
      case 'SYSTEM_BROADCAST':
        return Icons.volume_up_outlined;
      case 'STATUS_IN_PROGRESS':
        return Icons.refresh_rounded;
      case 'REPORT_RECEIVED':
      case 'ASSIGNMENT_CREATED':
      case 'WORK_VERIFIED':
      default:
        return Icons.article_outlined;
    }
  }

  Color _iconColor(String? type) {
    switch (type) {
      case 'AREA_WARNING':
        return AppColors.badgeAmberText;
      case 'STATUS_RESOLVED':
        return AppColors.grabGreenDark;
      case 'SYSTEM_BROADCAST':
        return AppColors.badgeGreenText;
      case 'STATUS_IN_PROGRESS':
        return AppColors.categoryChemical;
      case 'REPORT_RECEIVED':
      case 'ASSIGNMENT_CREATED':
      case 'WORK_VERIFIED':
      default:
        return AppColors.info;
    }
  }

  Color _iconBgColor(String? type) {
    switch (type) {
      case 'AREA_WARNING':
        return AppColors.badgeAmberBg;
      case 'STATUS_RESOLVED':
        return AppColors.grabMintBg;
      case 'SYSTEM_BROADCAST':
        return AppColors.badgeGreenBg;
      case 'STATUS_IN_PROGRESS':
        return AppColors.categoryChemicalBg;
      case 'REPORT_RECEIVED':
      case 'ASSIGNMENT_CREATED':
      case 'WORK_VERIFIED':
      default:
        return AppColors.badgeBlueBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final titleText = item.title.trim().endsWith('.')
        ? item.title.trim()
        : '${item.title.trim()}.';

    return Dismissible(
      key: Key('notif_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.spacingLg),
        color: AppColors.error,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 20),
            SizedBox(width: AppDimens.spacingXs),
            Text(
              'Xóa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      child: Material(
        color: isUnread ? AppColors.infoLight : Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingBase,
              vertical: AppDimens.spacingSm + 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon tròn pastel bên trái
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _iconBgColor(item.type),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _iconForType(item.type),
                      color: _iconColor(item.type),
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(width: AppDimens.spacingBase),

                // Nội dung text nối tiếp: Tiêu đề in đậm + Nội dung
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$titleText ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                height: 1.35,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextSpan(
                              text: item.message,
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 13.5,
                                height: 1.35,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 5),

                      // Mốc thời gian tương đối
                      Text(
                        item.relativeTime,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.w500,
                          color: isUnread
                              ? AppColors.info
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chấm xanh tròn báo chưa đọc bên phải
                if (isUnread) ...[
                  const SizedBox(width: AppDimens.spacingSm),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
