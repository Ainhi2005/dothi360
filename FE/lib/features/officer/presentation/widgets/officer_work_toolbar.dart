import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Thanh công cụ lọc & tìm kiếm nhiệm vụ của Cán bộ chuẩn format Grab UI
class OfficerWorkToolbar extends StatelessWidget {
  const OfficerWorkToolbar({
    required this.scope,
    required this.filter,
    required this.onScopeChanged,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.sort,
    required this.onSortChanged,
    this.queueCount,
    this.mineCount,
    super.key,
  });

  final String scope;
  final String filter;
  final ValueChanged<String> onScopeChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final String sort;
  final ValueChanged<String> onSortChanged;
  final int? queueCount;
  final int? mineCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 Tab chọn phạm vi chuẩn Pill Tab Bar
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          ),
          child: Row(
            children: [
              _ScopeTab(
                label: queueCount != null && queueCount! > 0
                    ? 'Chờ nhận ($queueCount)'
                    : 'Chờ nhận',
                isSelected: scope == 'queue',
                onTap: () => onScopeChanged('queue'),
              ),
              _ScopeTab(
                label: mineCount != null && mineCount! > 0
                    ? 'Đang làm ($mineCount)'
                    : 'Đang làm',
                isSelected: scope == 'mine',
                onTap: () => onScopeChanged('mine'),
              ),
              _ScopeTab(
                label: 'Lịch sử đã xong',
                isSelected: scope == 'history',
                onTap: () => onScopeChanged('history'),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimens.spacingSm),

        // Ô tìm kiếm bo tròn nhẹ nhàng
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            onChanged: onSearchChanged,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Tìm loại sự cố, địa chỉ, mô tả...',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textDisabled,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        const SizedBox(height: AppDimens.spacingSm),

        // Hàng bộ lọc nhanh & Sắp xếp
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipItem(
                      label: 'Tất cả',
                      isSelected: filter == 'all',
                      onTap: () => onFilterChanged('all'),
                    ),
                    const SizedBox(width: 6),
                    _FilterChipItem(
                      label: 'Khẩn cấp 🚨',
                      isSelected: filter == 'urgent',
                      onTap: () => onFilterChanged('urgent'),
                    ),
                    const SizedBox(width: 6),
                    _FilterChipItem(
                      label: 'Quá SLA ⏱️',
                      isSelected: filter == 'overdue',
                      onTap: () => onFilterChanged('overdue'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Nút sắp xếp gọn gàng
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButton<String>(
                value: sort,
                isDense: true,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.sort_rounded, size: 16, color: AppColors.textSecondary),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                items: const [
                  DropdownMenuItem(value: 'priority', child: Text('Ưu tiên cao')),
                  DropdownMenuItem(value: 'sla', child: Text('Gần quá hạn')),
                  DropdownMenuItem(value: 'distance', child: Text('Gần nhất')),
                ],
                onChanged: (val) {
                  if (val != null) onSortChanged(val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScopeTab extends StatelessWidget {
  const _ScopeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: AppColors.shadowSubtle,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.grabGreenDark : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.grabGreenLight : Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.grabGreen : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.grabGreenDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
