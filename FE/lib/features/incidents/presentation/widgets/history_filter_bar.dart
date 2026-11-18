import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class HistoryFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final int allCount;
  final int processingCount;
  final int resolvedCount;

  const HistoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.allCount = 0,
    this.processingCount = 0,
    this.resolvedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'key': 'ALL', 'label': 'Tất cả ($allCount)'},
      {'key': 'PROCESSING', 'label': 'Đang xử lý ($processingCount)'},
      {'key': 'RESOLVED', 'label': 'Đã xử lý ($resolvedCount)'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.searchBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = selected == item['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(item['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  item['label']!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
