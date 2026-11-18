import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../data/models/officer_assignment_model.dart';

class OfficerWorkspaceHeader extends StatelessWidget {
  const OfficerWorkspaceHeader({
    required this.assignment,
    super.key,
  });

  final OfficerAssignmentModel assignment;

  String _formatSla(DateTime? deadline, bool isOverdue) {
    if (deadline == null) return '';
    final now = DateTime.now();
    if (isOverdue) {
      final diff = now.difference(deadline);
      if (diff.inHours > 0) return 'Quá hạn ${diff.inHours} giờ';
      return 'Quá hạn ${diff.inMinutes.clamp(1, 60)} phút';
    }
    final diff = deadline.difference(now);
    if (diff.inHours > 0) return 'Còn ${diff.inHours} giờ';
    if (diff.inMinutes > 0) return 'Còn ${diff.inMinutes} phút';
    return 'Hạn xử lý: sắp hết';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = assignment.isUrgent;
    final isOverdue = assignment.isOverdue;
    final slaText = _formatSla(assignment.slaDeadline, isOverdue);

    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: isUrgent
              ? AppColors.errorBorder
              : (isOverdue ? AppColors.warningBorder : AppColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  'PA-${assignment.incidentId.substring(0, assignment.incidentId.length > 8 ? 8 : assignment.incidentId.length).toUpperCase()}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              AppStatusBadge(
                status: assignment.wasRejected
                    ? 'REJECTED'
                    : (assignment.wasReassigned
                        ? 'CANCELLED'
                        : (assignment.wasCompleted
                            ? 'RESOLVED'
                            : assignment.status)),
                customLabel: assignment.assignmentLabel,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSm),
          Text(
            assignment.incidentTypeName,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimens.spacingSm),
          Wrap(
            spacing: AppDimens.spacingSm,
            runSpacing: AppDimens.spacingXs,
            children: [
              if (isUrgent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 13,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ƯU TIÊN CAO',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              if (slaText.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? AppColors.warning.withValues(alpha: 0.12)
                        : AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOverdue
                            ? Icons.timer_off_outlined
                            : Icons.timer_outlined,
                        size: 13,
                        color: isOverdue
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SLA: $slaText',
                        style: AppTextStyles.caption.copyWith(
                          color: isOverdue
                              ? AppColors.warning
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              if (assignment.departmentName.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Text(
                    assignment.departmentName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: AppDimens.spacingLg),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: AppDimens.iconSizeSm,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimens.spacingXs),
              Expanded(
                child: Text(
                  assignment.address ?? 'Chưa cập nhật địa chỉ hiện trường',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
