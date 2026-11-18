import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class OfficerProgressFields extends StatelessWidget {
  const OfficerProgressFields({
    required this.progressPercent,
    required this.estimatedCompletionAt,
    required this.blockerController,
    required this.isPublic,
    required this.onProgressChanged,
    required this.onPickEta,
    required this.onVisibilityChanged,
    super.key,
  });

  final int progressPercent;
  final DateTime? estimatedCompletionAt;
  final TextEditingController blockerController;
  final bool isPublic;
  final ValueChanged<int> onProgressChanged;
  final VoidCallback onPickEta;
  final ValueChanged<bool> onVisibilityChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Mức độ hoàn thành',
                      style: AppTextStyles.titleMedium),
                ),
                Text('$progressPercent%', style: AppTextStyles.linkText),
              ],
            ),
            Slider(
              value: progressPercent.toDouble(),
              min: 0,
              max: 95,
              divisions: 19,
              label: '$progressPercent%',
              onChanged: (value) => onProgressChanged(value.round()),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.event_outlined, color: AppColors.primary),
              title: const Text('Dự kiến hoàn thành'),
              subtitle: Text(
                estimatedCompletionAt == null
                    ? 'Chưa xác định'
                    : '${estimatedCompletionAt!.day}/${estimatedCompletionAt!.month}/${estimatedCompletionAt!.year}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: onPickEta,
            ),
            TextField(
              controller: blockerController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Khó khăn hoặc nguyên nhân chậm (nếu có)',
                prefixIcon: Icon(Icons.report_problem_outlined),
              ),
            ),
            const SizedBox(height: AppDimens.spacingSm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: isPublic,
              onChanged: onVisibilityChanged,
              title: const Text('Chia sẻ với người dân'),
              subtitle: Text(
                isPublic
                    ? 'Cập nhật sẽ xuất hiện trên timeline công khai.'
                    : 'Chỉ cán bộ và quản trị viên nhìn thấy.',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      );
}
