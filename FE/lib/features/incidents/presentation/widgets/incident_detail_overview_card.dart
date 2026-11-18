import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/incident_detail_model.dart';
import 'incident_status_chip.dart';

/// Thẻ tổng quan trả lời ngay 3 câu hỏi chính và tóm tắt phản ánh
class IncidentDetailOverviewCard extends StatelessWidget {
  final IncidentDetailModel incident;

  const IncidentDetailOverviewCard({
    super.key,
    required this.incident,
  });

  String _getStatusExplanation(String status) {
    switch (status) {
      case 'RESOLVED':
        return 'Sự cố đã được khắc phục và hoàn tất nghiệm thu.';
      case 'PENDING_VERIFICATION':
        return 'Hiện trường đã xử lý xong, đang chờ cán bộ nghiệm thu kết quả.';
      case 'IN_PROGRESS':
        return 'Đội phản ứng nhanh đang trực tiếp xử lý tại hiện trường.';
      case 'ASSIGNED':
        return 'Đã phân công lực lượng chuyên trách tiếp nhận xử lý.';
      case 'PENDING_ASSIGNMENT':
      default:
        return 'Hệ thống đã tiếp nhận, đang điều phối tới đơn vị phụ trách.';
    }
  }

  String _getEstimatedDeadline() {
    if (incident.status == 'RESOLVED' && incident.resolvedAt != null) {
      return 'Hoàn thành: ${DateTimeFormatter.dateTime(incident.resolvedAt!)}';
    }

    final latestUpdate =
        incident.updates.isNotEmpty ? incident.updates.first : null;
    if (latestUpdate?.estimatedCompletionAt != null) {
      return 'Dự kiến xong: ${DateTimeFormatter.dateTime(latestUpdate!.estimatedCompletionAt!)}';
    }

    final slaHours = incident.aiAnalysis?['suggested_sla_hours']?.toString();
    if (slaHours != null) {
      return 'Thời hạn SLA xử lý: trong $slaHours giờ';
    }

    return 'Dự kiến: Đang cập nhật tiến độ';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BA CÂU HỎI TRỌNG TÂM TRẢ LỜI NGAY (HERO 3-QUESTIONS BOX)
          Container(
            padding: const EdgeInsets.all(AppDimens.spacingSm + 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Câu 1: Trạng thái hiện tại
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: AppDimens.iconSizeSm,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppDimens.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Trạng thái: ',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              IncidentStatusChip(status: incident.status),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getStatusExplanation(incident.status),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppDimens.spacingSm),
                  child: Divider(height: 1, color: AppColors.divider),
                ),

                // Câu 2: Đơn vị đang xử lý
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: AppDimens.iconSizeSm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimens.spacingSm),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đơn vị thụ lý:',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              incident.departmentName ?? 'Đang phân công',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppDimens.spacingSm),
                  child: Divider(height: 1, color: AppColors.divider),
                ),

                // Câu 3: Thời hạn dự kiến / Cập nhật tiếp theo
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: AppDimens.iconSizeSm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimens.spacingSm),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kế hoạch xử lý:',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              _getEstimatedDeadline(),
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),

          // 2. TÓM TẮT GỌN (LOẠI SỰ CỐ & MÔ TẢ NGƯỜI DÂN)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  incident.incidentTypeName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingSm,
                  vertical: AppDimens.spacing2Xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${incident.reportCount} xác nhận',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSm),

          // Mô tả người dân (Sạch sẽ, không lồng card trong card)
          Text(
            incident.description.trim().isEmpty
                ? 'Không có mô tả chi tiết từ người dân.'
                : incident.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppDimens.spacingSm),

          // Thời gian gửi
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: AppColors.textDisabled,
              ),
              const SizedBox(width: 4),
              Text(
                'Gửi lúc: ${DateTimeFormatter.dateTime(incident.createdAt)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
