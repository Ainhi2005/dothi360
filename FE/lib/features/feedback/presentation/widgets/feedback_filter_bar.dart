import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class FeedbackFilterBar extends StatelessWidget {
  const FeedbackFilterBar({
    required this.selectedCategory,
    required this.onSelectCategory,
    super.key,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  static const _categories = [
    {'key': 'ALL', 'label': 'Tất cả'},
    {'key': 'TRAFFIC', 'label': 'Giao thông'},
    {'key': 'GREENERY', 'label': 'Cây xanh'},
    {'key': 'LIGHTING', 'label': 'Chiếu sáng'},
    {'key': 'DRAINAGE', 'label': 'Thoát nước'},
    {'key': 'ENVIRONMENT', 'label': 'Môi trường'},
    {'key': 'GENERAL', 'label': 'Chung'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingBase),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimens.spacingSm),
        itemBuilder: (context, index) {
          final item = _categories[index];
          final isSelected = item['key'] == selectedCategory;

          return ChoiceChip(
            label: Text(
              item['label']!,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            onSelected: (_) => onSelectCategory(item['key']!),
          );
        },
      ),
    );
  }
}

