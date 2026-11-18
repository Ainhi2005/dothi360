import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../core/utils/incident_code_formatter.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../data/models/report_history_model.dart';
import 'incident_status_chip.dart';

class HistoryReportCard extends StatelessWidget {
  final ReportHistoryModel report;
  final VoidCallback onTap;

  const HistoryReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final code = IncidentCodeFormatter.format(
      report.incidentId.isNotEmpty ? report.incidentId : report.reportId,
      report.createdAt,
    );
    final isResolved = report.status == 'RESOLVED';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd + 4),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd + 4),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spacingSm + 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HistoryThumbnail(
                  urls: report.imageUrls,
                  isResolved: isResolved,
                ),
                const SizedBox(width: AppDimens.spacingSm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            code,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          IncidentStatusChip(status: report.status),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        report.incidentTypeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        report.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.spacingSm),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              DateTimeFormatter.dateTime(report.createdAt),
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.group_outlined,
                            size: 14,
                            color: AppColors.emergencySuccessText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${report.reportCount} người cùng báo',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.emergencySuccessText,
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
        ),
      ),
    );
  }
}

class _HistoryThumbnail extends StatelessWidget {
  final List<String> urls;
  final bool isResolved;

  const _HistoryThumbnail({
    required this.urls,
    required this.isResolved,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = urls.isNotEmpty;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: SizedBox(
            width: 82,
            height: 82,
            child: hasImage
                ? AppCachedImage(
                    imageUrl: urls.first,
                    fit: BoxFit.cover,
                    memCacheWidth: 250,
                  )
                : _buildPlaceholder(),
          ),
        ),
        if (isResolved)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.homeGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        if (urls.length > 1 && !isResolved)
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.crop_original_outlined,
                    color: Colors.white,
                    size: 10,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${urls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.location_city, color: AppColors.primary, size: 30),
      ),
    );
  }
}
