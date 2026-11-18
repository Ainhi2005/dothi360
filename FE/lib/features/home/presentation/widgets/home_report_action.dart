import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class HomeReportAction extends StatelessWidget {
  const HomeReportAction({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.surface,
                  child: Icon(Icons.add, color: AppColors.primary),
                ),
                const SizedBox(width: AppDimens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tạo phản ánh mới',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                      Text(
                        'Góp phần xây dựng đô thị tốt đẹp hơn',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.surface),
              ],
            ),
          ),
        ),
      );
}
