import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../data/models/officer_assignment_model.dart';

/// Thẻ nhiệm vụ ưu tiên tiếp theo của cán bộ (tái sử dụng AppCard, AppButton từ core)
class OfficerHeroUrgentCard extends StatelessWidget {
  const OfficerHeroUrgentCard({
    required this.task,
    required this.onTapDetail,
    required this.onOneTapAction,
    this.isActionLoading = false,
    super.key,
  });

  final OfficerAssignmentModel? task;
  final VoidCallback onTapDetail;
  final VoidCallback onOneTapAction;
  final bool isActionLoading;

  String _formatSla(DateTime? deadline, bool isOverdue) {
    if (deadline == null) return '';
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (isOverdue) {
      final overdueDiff = now.difference(deadline);
      if (overdueDiff.inHours > 0) {
        return 'Quá hạn ${overdueDiff.inHours}h';
      }
      return 'Quá hạn ${overdueDiff.inMinutes.clamp(1, 60)}p';
    }
    if (diff.inHours > 0) {
      return 'Còn ${diff.inHours} giờ';
    }
    if (diff.inMinutes > 0) {
      return 'Còn ${diff.inMinutes} phút';
    }
    return 'Đến hạn ngay';
  }

  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return AppEmptyState(
        icon: Icons.task_alt_rounded,
        title: 'Ca trực hiện tại ổn định',
        description: 'Không có nhiệm vụ khẩn cấp hay quá hạn SLA cần hành động ngay.',
        minHeight: 180,
        action: AppButton(
          label: 'Mở bàn công việc',
          onPressed: onTapDetail,
          type: AppButtonType.secondary,
          isFullWidth: false,
        ),
      );
    }

    final isUrgent = task!.isUrgent;
    final isOverdue = task!.isOverdue;
    final isWaiting = task!.isWaiting;
    final deadlineText = _formatSla(task!.slaDeadline, isOverdue);

    final borderColor = isUrgent
        ? AppColors.errorBorder
        : (isOverdue ? AppColors.warningBorder : AppColors.border);

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      borderColor: borderColor,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header thẻ: Loại nhiệm vụ + Thời hạn SLA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? AppColors.errorLight
                      : (isWaiting ? AppColors.badgeAmberBg : AppColors.grabMintBg),
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUrgent
                          ? Icons.warning_amber_rounded
                          : (isWaiting ? Icons.hourglass_top_rounded : Icons.check_circle_outline),
                      size: 13,
                      color: isUrgent
                          ? AppColors.error
                          : (isWaiting ? AppColors.badgeAmberText : AppColors.grabGreenDark),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUrgent
                          ? 'KHẨN CẤP'
                          : (isWaiting ? 'CHỜ TIẾP NHẬN' : 'NHIỆM VỤ TIẾP THEO'),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isUrgent
                            ? AppColors.error
                            : (isWaiting ? AppColors.badgeAmberText : AppColors.grabGreenDark),
                      ),
                    ),
                  ],
                ),
              ),
              if (deadlineText.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: isOverdue ? AppColors.error : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      deadlineText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: AppDimens.spacingSm),

          // Nội dung sự cố: Ảnh thumbnail + Tiêu đề + Địa chỉ + Mô tả
          InkWell(
            onTap: onTapDetail,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task!.coverUrl != null && task!.coverUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    child: AppCachedImage(
                      imageUrl: task!.coverUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task!.incidentTypeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        task!.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.groups_outlined,
                            size: 13,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${task!.reportCount} phản ánh của dân',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.spacingMd),

          // Hàng nút thao tác chuẩn AppButton từ core
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: isWaiting ? 'Tiếp nhận xử lý' : 'Cập nhật hiện trường',
                  icon: isWaiting
                      ? Icons.check_circle_outline
                      : Icons.edit_note_rounded,
                  isLoading: isActionLoading,
                  onPressed: onOneTapAction,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingSm,
                  ),
                  iconSize: 18,
                ),
              ),
              const SizedBox(width: AppDimens.spacingSm),
              SizedBox(
                width: 94,
                child: AppButton(
                  label: 'Chi tiết',
                  type: AppButtonType.secondary,
                  onPressed: onTapDetail,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingSm,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
