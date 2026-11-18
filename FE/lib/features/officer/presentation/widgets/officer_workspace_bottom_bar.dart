import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/officer_assignment_model.dart';

class OfficerWorkspaceBottomBar extends StatelessWidget {
  const OfficerWorkspaceBottomBar({
    required this.assignment,
    required this.onAccept,
    required this.onUpdateStatus,
    required this.onReject,
    this.isLoading = false,
    super.key,
  });

  final OfficerAssignmentModel assignment;
  final VoidCallback onAccept;
  final VoidCallback onUpdateStatus;
  final VoidCallback onReject;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isWaiting = assignment.isWaiting;
    final isPendingVerification = assignment.status == 'PENDING_VERIFICATION';
    final isCompleted = assignment.wasCompleted ||
        ['RESOLVED', 'REJECTED', 'CANCELLED'].contains(assignment.status);
    final isAssignedOrAccepted =
        assignment.status == 'ASSIGNED' || assignment.status == 'ACCEPTED';

    if (assignment.wasRejected || assignment.wasReassigned) {
      final rejected = assignment.wasRejected;
      return Container(
        padding: EdgeInsets.only(
          left: AppDimens.spacingMd,
          right: AppDimens.spacingMd,
          top: AppDimens.spacingSm,
          bottom: MediaQuery.paddingOf(context).bottom + AppDimens.spacingSm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.spacingSm,
            horizontal: AppDimens.spacingMd,
          ),
          decoration: BoxDecoration(
            color: (rejected ? AppColors.error : AppColors.warning)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            border: Border.all(
              color: rejected
                  ? AppColors.errorBorder
                  : AppColors.warningBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                rejected
                    ? Icons.assignment_return_outlined
                    : Icons.swap_horiz_rounded,
                color: rejected ? AppColors.error : AppColors.warning,
                size: AppDimens.iconSizeSm,
              ),
              const SizedBox(width: AppDimens.spacingSm),
              Flexible(
                child: Text(
                  rejected
                      ? 'Bạn đã từ chối nhiệm vụ này'
                      : 'Nhiệm vụ đã được điều chuyển',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: rejected ? AppColors.error : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: AppDimens.spacingMd,
        right: AppDimens.spacingMd,
        top: AppDimens.spacingSm,
        bottom: MediaQuery.paddingOf(context).bottom + AppDimens.spacingSm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SafeArea(
        top: false,
        child: isWaiting
            ? Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.spacingSm),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : onAccept,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Tiếp nhận nhiệm vụ ngay'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      ),
                    ),
                  ),
                ),
              ])
            : isPendingVerification
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.spacingSm,
                      horizontal: AppDimens.spacingMd,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      border: Border.all(color: AppColors.warningBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: AppDimens.spacingSm),
                        Text(
                          'Đã gửi báo cáo · Đang chờ nghiệm thu',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  )
                : isCompleted
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimens.spacingSm,
                          horizontal: AppDimens.spacingMd,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusSm),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.task_alt_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: AppDimens.spacingSm),
                            Text(
                              'Hồ sơ sự cố đã hoàn tất',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : isAssignedOrAccepted
                        ? FilledButton.icon(
                            onPressed: onUpdateStatus,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text(
                              'Bắt đầu xử lý',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusSm),
                              ),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: onUpdateStatus,
                            icon: const Icon(Icons.edit_note_rounded),
                            label: const Text(
                              'Cập nhật tiến độ / Nghiệm thu',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusSm),
                              ),
                            ),
                          ),
      ),
    );
  }
}
