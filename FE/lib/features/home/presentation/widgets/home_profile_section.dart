import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import 'home_report_row.dart';

/// Khối tổng quan hồ sơ phản ánh của người dân (Civic Citizen Profile Card)
class HomeProfileSection extends StatelessWidget {
  const HomeProfileSection({
    super.key,
    required this.activeReports,
    required this.resolvedCount,
    required this.totalCount,
    required this.onViewAll,
  });

  final List<Map<String, dynamic>> activeReports;
  final int resolvedCount;
  final int totalCount;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Link xem tất cả
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hồ sơ của bạn',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingXs),

          // Dải chỉ số thống kê hồ sơ (Flat KPI Strip)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingBase,
              vertical: AppDimens.spacingBase,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _ProfileMetric(
                  value: activeReports.length,
                  label: 'Đang xử lý',
                  highlight: activeReports.isNotEmpty,
                ),
                const _MetricDivider(),
                _ProfileMetric(
                  value: resolvedCount,
                  label: 'Hoàn thành',
                ),
                const _MetricDivider(),
                _ProfileMetric(
                  value: totalCount,
                  label: 'Tổng hồ sơ',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.spacingSm),

          // Danh sách phản ánh đang xử lý
          if (activeReports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimens.spacingBase,
                horizontal: AppDimens.spacingSm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: AppDimens.iconSizeBase,
                  ),
                  const SizedBox(width: AppDimens.spacingSm),
                  Expanded(
                    child: Text(
                      'Bạn không có phản ánh nào đang xử lý.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            for (var index = 0;
                index < activeReports.length && index < 2;
                index++) ...[
              HomeReportRow(report: activeReports[index]),
              if (index == 0 && activeReports.length > 1)
                const Divider(height: 1, color: AppColors.divider),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final int value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: AppTextStyles.metricMedium.copyWith(
              color: highlight ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        color: AppColors.border,
      );
}
