import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class HistoryEmptyState extends StatelessWidget {
  final VoidCallback onCreateReport;

  const HistoryEmptyState({super.key, required this.onCreateReport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.receipt_long_outlined,
                  size: 42, color: AppColors.primary),
            ),
            const SizedBox(height: AppDimens.spacingMd),
            const Text('Chưa có phản ánh', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppDimens.spacingSm),
            const Text(
              'Các phản ánh bạn đã gửi sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimens.spacingLg),
            AppButton(
              label: 'Tạo phản ánh',
              icon: Icons.add_a_photo_outlined,
              isFullWidth: false,
              onPressed: onCreateReport,
            ),
          ],
        ),
      ),
    );
  }
}
