import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/citizen_feedback_model.dart';

class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    required this.feedback,
    required this.onToggleUpvote,
    super.key,
  });

  final CitizenFeedbackModel feedback;
  final VoidCallback onToggleUpvote;

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'TRAFFIC':
        return 'Giao thông';
      case 'GREENERY':
        return 'Cây xanh';
      case 'LIGHTING':
        return 'Chiếu sáng';
      case 'DRAINAGE':
        return 'Thoát nước';
      case 'ENVIRONMENT':
        return 'Môi trường';
      default:
        return 'Góp ý chung';
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'TRAFFIC':
        return AppColors.info;
      case 'GREENERY':
        return AppColors.grabGreen;
      case 'LIGHTING':
        return AppColors.warning;
      case 'DRAINAGE':
        return AppColors.categoryFlood;
      case 'ENVIRONMENT':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(feedback.category);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.spacingMd),
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Text(
                  _categoryLabel(feedback.category),
                  style: AppTextStyles.caption.copyWith(
                    color: catColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: onToggleUpvote,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        feedback.isUpvoted
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        size: 16,
                        color: feedback.isUpvoted
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${feedback.upvotes}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: feedback.isUpvoted
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSm),
          Text(
            feedback.title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            feedback.content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (feedback.locationName != null &&
              feedback.locationName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    feedback.locationName!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (feedback.adminResponse != null &&
              feedback.adminResponse!.isNotEmpty) ...[
            const SizedBox(height: AppDimens.spacingSm),
            Container(
              padding: const EdgeInsets.all(AppDimens.spacingSm),
              decoration: BoxDecoration(
                color: feedback.status == 'ACCEPTED'
                    ? AppColors.badgeGreenBg
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feedback.status == 'ACCEPTED'
                        ? '✓ Chính quyền tiếp thu & ghi nhận:'
                        : '✗ Ý kiến từ cơ quan chức năng:',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: feedback.status == 'ACCEPTED'
                          ? AppColors.grabGreenDark
                          : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feedback.adminResponse!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimens.spacingSm),
          Text(
            '${feedback.userName} · ${_formatDate(feedback.createdAt)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textDisabled,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

