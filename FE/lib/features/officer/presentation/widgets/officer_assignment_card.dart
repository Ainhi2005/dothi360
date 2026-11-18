import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../data/models/officer_assignment_model.dart';

/// Thẻ nhiệm vụ của cán bộ tái sử dụng AppCard, AppStatusBadge từ core
class OfficerAssignmentCard extends StatelessWidget {
  const OfficerAssignmentCard({
    required this.assignment,
    required this.onTap,
    super.key,
  });

  final OfficerAssignmentModel assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final urgent = assignment.priorityLevel == 'EMERGENCY' ||
        assignment.priorityLevel == 'HIGH';
    final assignedTime =
        TimeOfDay.fromDateTime(assignment.assignedAt.toLocal()).format(context);

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      elevation: 0,
      borderColor: urgent ? AppColors.errorBorder : AppColors.border,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (assignment.coverUrl != null &&
                  assignment.coverUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: AppCachedImage(
                      imageUrl: assignment.coverUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.spacingSm + 2),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            assignment.incidentTypeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
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
                    const SizedBox(height: 3),
                    Text(
                      assignment.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assignment.reworkRequired
                          ? 'Admin yêu cầu xử lý bổ sung'
                          : assignment.isOverdue
                              ? 'Đã quá thời hạn SLA'
                              : '${urgent ? 'Ưu tiên cao' : 'Ưu tiên thường'} · Giao $assignedTime',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                        color: assignment.reworkRequired ||
                                assignment.isOverdue ||
                                urgent
                            ? AppColors.error
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSm),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.groups_outlined,
                  size: 13,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 3),
                Text(
                  '${assignment.reportCount} phản ánh',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10.5,
                  ),
                ),
                if (assignment.distanceM != null) ...[
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.near_me_outlined,
                    size: 13,
                    color: AppColors.grabGreenDark,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${(assignment.distanceM! / 1000).toStringAsFixed(1)} km',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grabGreenDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.5,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  assignment.canAct
                      ? (assignment.isWaiting
                          ? 'Tiếp nhận ngay'
                          : 'Xử lý nhiệm vụ')
                      : 'Xem lịch sử',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grabGreenDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  size: 15,
                  color: AppColors.grabGreenDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
