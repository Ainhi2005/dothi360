import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/create_report_controller.dart';

/// Ô lựa chọn phân loại sự cố thủ công (Fallback rõ ràng)
class IncidentTypeSelector extends ConsumerWidget {
  const IncidentTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createReportProvider);
    final controller = ref.read(createReportProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Phân loại sự cố',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingSm,
                vertical: AppDimens.spacing2Xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Tùy chọn',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.spacingXs),
        Text(
          'AI sẽ tự nhận diện từ ảnh. Chọn thủ công nếu bạn muốn chỉ định trước.',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimens.spacingSm),
        DropdownButtonFormField<String>(
          initialValue: state.incidentTypeId,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Để trống để AI tự nhận diện',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDisabled,
            ),
            prefixIcon: const Icon(
              Icons.category_outlined,
              size: AppDimens.iconSizeSm,
              color: AppColors.textSecondary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingMd,
              vertical: AppDimens.spacingSm + 2,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Tự động theo phân tích AI',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ...state.incidentTypes.map((item) {
              return DropdownMenuItem<String>(
                value: item['id']?.toString(),
                child: Text(
                  item['name']?.toString() ?? 'Khác',
                  style: AppTextStyles.bodyMedium,
                ),
              );
            }),
          ],
          onChanged: controller.selectIncidentType,
        ),
      ],
    );
  }
}
