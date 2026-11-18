import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class EmergencyCategoryChips extends StatelessWidget {
  const EmergencyCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelected;

  static const categories = [
    ('ALL', 'Tất cả'),
    ('NATIONAL', 'Quốc gia (113-115)'),
    ('INFRASTRUCTURE', 'Hạ tầng đô thị'),
    ('TRAFFIC', 'Giao thông & Cứu hộ'),
    ('MEDICAL', 'Y tế & Dịch bệnh'),
    ('SECURITY', 'An ninh & Trật tự'),
    ('RESCUE', 'Cứu nạn bão lũ'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimens.spacingSm),
        itemBuilder: (context, index) {
          final (key, label) = categories[index];
          final isSelected = selectedCategory == key;

          return FilterChip(
            selected: isSelected,
            label: Text(label),
            labelStyle: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            showCheckmark: false,
            onSelected: (_) => onSelected(key),
          );
        },
      ),
    );
  }
}
