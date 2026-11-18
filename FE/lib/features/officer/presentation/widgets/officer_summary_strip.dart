import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/officer_dashboard_model.dart';

/// Thẻ thống kê 4 chỉ số ca trực cán bộ tái sử dụng AppCard từ core
class OfficerSummaryStrip extends StatelessWidget {
  const OfficerSummaryStrip({
    required this.summary,
    this.onTapItem,
    super.key,
  });

  final OfficerDashboardModel summary;
  final ValueChanged<String>? onTapItem;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        key: 'queue',
        label: 'Chờ nhận',
        count: summary.queue,
        color: summary.queue > 0 ? AppColors.badgeAmberText : AppColors.textPrimary,
      ),
      (
        key: 'mine',
        label: 'Của tôi',
        count: summary.mine,
        color: summary.mine > 0 ? AppColors.grabGreenDark : AppColors.textPrimary,
      ),
      (
        key: 'urgent',
        label: 'Khẩn cấp',
        count: summary.urgent,
        color: summary.urgent > 0 ? AppColors.error : AppColors.textPrimary,
      ),
      (
        key: 'overdue',
        label: 'Quá SLA',
        count: summary.overdue,
        color: summary.overdue > 0 ? AppColors.warning : AppColors.textSecondary,
      ),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.horizontal(
                      left: index == 0
                          ? const Radius.circular(AppDimens.radiusLg)
                          : Radius.zero,
                      right: index == items.length - 1
                          ? const Radius.circular(AppDimens.radiusLg)
                          : Radius.zero,
                    ),
                    onTap: onTapItem != null
                        ? () => onTapItem!(items[index].key)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.spacingMd,
                        horizontal: AppDimens.spacing2Xs,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${items[index].count}',
                            style: AppTextStyles.headingMedium.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: items[index].color,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[index].label,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (index < items.length - 1)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.divider,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
