import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/officer_assignment_model.dart';

class OfficerNextActionCard extends StatelessWidget {
  const OfficerNextActionCard({
    required this.assignment,
    super.key,
  });

  final OfficerAssignmentModel assignment;

  @override
  Widget build(BuildContext context) {
    late final String title;
    late final String description;
    late final IconData icon;
    late final Color color;
    late final Color bgColor;

    if (assignment.wasRejected) {
      title = 'Nhiệm vụ đã được bạn từ chối';
      description = assignment.rejectionReason?.trim().isNotEmpty == true
          ? 'Lý do: ${assignment.rejectionReason}'
          : 'Hồ sơ đã được trả về hàng chờ để điều phối viên phân công lại.';
      icon = Icons.assignment_return_outlined;
      color = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.08);
    } else if (assignment.wasReassigned) {
      title = 'Nhiệm vụ không còn thuộc phạm vi xử lý';
      description =
          'Điều phối viên đã chuyển hồ sơ sang cán bộ hoặc đơn vị khác. Bạn chỉ có thể xem lịch sử.';
      icon = Icons.swap_horiz_rounded;
      color = AppColors.warning;
      bgColor = AppColors.warning.withValues(alpha: 0.08);
    } else if (assignment.isWaiting) {
      title = 'Bước 1: Tiếp nhận nhiệm vụ';
      description =
          'Hồ sơ đang chờ đơn vị nhận việc. Vui lòng bấm Tiếp nhận để xác nhận phụ trách xử lý hiện trường.';
      icon = Icons.assignment_turned_in_outlined;
      color = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.08);
    } else if (assignment.reworkRequired) {
      title = 'Cần xử lý bổ sung theo yêu cầu Admin';
      description =
          'Báo cáo trước đó chưa đạt tiêu chuẩn nghiệm thu. Hãy kiểm tra lại hiện trường và gửi minh chứng bổ sung.';
      icon = Icons.replay_rounded;
      color = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.08);
    } else if (assignment.status == 'PENDING_VERIFICATION') {
      title = 'Đang chờ điều phối viên nghiệm thu';
      description =
          'Bạn đã hoàn thành xử lý và gửi minh chứng. Kết quả đang được đối soát trước khi đóng hồ sơ.';
      icon = Icons.hourglass_top_rounded;
      color = AppColors.warning;
      bgColor = AppColors.warning.withValues(alpha: 0.08);
    } else if (['RESOLVED', 'REJECTED', 'CANCELLED']
        .contains(assignment.status)) {
      title = 'Nhiệm vụ đã hoàn tất';
      description =
          'Sự cố đã được nghiệm thu và lưu trữ vào hồ sơ lịch sử tác nghiệp.';
      icon = Icons.task_alt_rounded;
      color = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.08);
    } else if (assignment.status == 'ASSIGNED' ||
        assignment.status == 'ACCEPTED') {
      title = 'Bước 2: Bắt đầu xử lý hiện trường';
      description =
          'Xác nhận bạn đã tiếp cận hiện trường và bắt đầu triển khai các bước xử lý.';
      icon = Icons.play_circle_outline_rounded;
      color = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.08);
    } else {
      title = 'Bước 3: Đang xử lý & hoàn thiện checklist';
      description =
          'Thực hiện checklist kỹ thuật xuyên suốt công việc. Bạn có thể cập nhật tiến độ thi công bất cứ lúc nào và nộp nghiệm thu khi hoàn tất.';
      icon = Icons.handyman_outlined;
      color = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.08);
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppDimens.iconSizeMd),
          const SizedBox(width: AppDimens.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
