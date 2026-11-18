import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/create_report_controller.dart';
import 'incident_type_selector.dart';

/// Thẻ nhập mô tả sự cố và phân loại thủ công
class DescriptionCard extends ConsumerWidget {
  const DescriptionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = ref.watch(
      createReportProvider.select((state) => state.description),
    );
    final controller = ref.read(createReportProvider.notifier);

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: AppDimens.iconSizeBase,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimens.spacingSm),
              Text(
                'Mô tả sự cố',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppDimens.spacingXs),
              Text(
                '*',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingXs),
          Text(
            'Mô tả hiện trạng thực tế, mốc nhận diện hoặc dấu hiệu nguy hiểm.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),
          TextFormField(
            initialValue: description,
            maxLines: 3,
            maxLength: 500,
            onChanged: controller.updateDescription,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText:
                  'Ví dụ: Cây xanh gãy cành chắn ngang lối đi, nguy cơ rơi xuống đường dây điện...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDisabled,
              ),
              contentPadding: const EdgeInsets.all(AppDimens.spacingMd),
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
              counterText: '${description.length}/500',
              counterStyle: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppDimens.spacingMd),
          const IncidentTypeSelector(),
        ],
      ),
    );
  }
}
