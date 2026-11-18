import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Thanh tìm kiếm và bộ lọc trạng thái nổi trên bản đồ số
class MapFloatingSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedStatusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onClearSearch;

  const MapFloatingSearchBar({
    super.key,
    required this.searchController,
    required this.selectedStatusFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onClearSearch,
  });

  static const _filters = [
    {'key': 'ALL', 'label': 'Tất cả'},
    {'key': 'PENDING_ASSIGNMENT', 'label': 'Chờ phân công'},
    {'key': 'ACCEPTED', 'label': 'Đã tiếp nhận'},
    {'key': 'IN_PROGRESS', 'label': 'Đang xử lý'},
    {'key': 'PENDING_VERIFICATION', 'label': 'Chờ nghiệm thu'},
    {'key': 'RESOLVED', 'label': 'Hoàn thành'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Ô tìm kiếm nổi
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimens.spacingSm + 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: AppDimens.spacingMd),
                child: Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: AppDimens.iconSizeBase,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: searchController,
                  style: AppTextStyles.bodyMedium,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tìm sự cố, địa điểm, từ khóa...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textDisabled,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spacingSm,
                      vertical: AppDimens.spacingSm + 2,
                    ),
                  ),
                ),
              ),
              if (searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: onClearSearch,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.spacingSm),

        // 2. Dải lọc nhanh trạng thái
        SizedBox(
          height: 32,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingSm + 4,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppDimens.spacingXs + 2),
            itemBuilder: (context, index) {
              final f = _filters[index];
              final isSelected = selectedStatusFilter == f['key'];

              return InkWell(
                onTap: () => onFilterChanged(f['key']!),
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingSm + 4,
                    vertical: AppDimens.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    f['label']!,
                    style: AppTextStyles.caption.copyWith(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
