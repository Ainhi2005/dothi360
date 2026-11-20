import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OfficerChecklistDialog extends StatelessWidget {
  const OfficerChecklistDialog({required this.missingRequired, super.key});
  final int missingRequired;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Cảnh báo thiếu Checklist'),
        content: Text(
          'Hiện trường còn $missingRequired mục bắt buộc trong checklist chưa đánh dấu hoàn thành.\n\nBạn có chắc chắn muốn nộp minh chứng nghiệm thu lúc này không?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Kiểm tra lại')),
          FilledButton(
            onPressed: () => context.pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Vẫn nộp'),
          ),
        ],
      );
}
