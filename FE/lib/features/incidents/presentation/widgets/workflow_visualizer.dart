import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class WorkflowVisualizer extends StatelessWidget {
  const WorkflowVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sau khi gửi',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppDimens.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStep(Icons.search, 'Kiểm tra trùng'),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
              _buildStep(Icons.flag_outlined, 'Tính ưu tiên'),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
              _buildStep(Icons.people_outline, 'Phân công đơn vị'),
            ],
          ),
          const SizedBox(height: AppDimens.spacingLg),
          Center(
            child: Text(
              'Kết quả xử lý sẽ được gửi qua thông báo.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimens.spacingMd),
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(height: AppDimens.spacingSm),
        Text(
          label,
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
