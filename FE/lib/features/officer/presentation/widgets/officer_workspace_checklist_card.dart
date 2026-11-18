import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class OfficerWorkspaceChecklistCard extends StatelessWidget {
  const OfficerWorkspaceChecklistCard({
    required this.checklist,
    required this.onItemChanged,
    required this.onSave,
    this.isSaving = false,
    super.key,
  });

  final List<Map<String, dynamic>> checklist;
  final void Function(int index, bool completed) onItemChanged;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final total = checklist.length;
    final completedCount =
        checklist.where((x) => x['completed'] == true).length;
    final requiredMissing = checklist
        .where((x) => x['is_required'] == true && x['completed'] != true)
        .length;
    final progress = total > 0 ? completedCount / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color:
              requiredMissing > 0 ? AppColors.warningBorder : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Checklist hiện trường',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppDimens.spacingXs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: completedCount == total && total > 0
                                ? AppColors.primaryLight
                                : AppColors.surfaceSubtle,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusSm),
                          ),
                          child: Text(
                            '$completedCount/$total',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: completedCount == total && total > 0
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      requiredMissing > 0
                          ? 'Còn $requiredMissing mục bắt buộc cần hoàn thành.'
                          : (total > 0
                              ? 'Đã đủ điều kiện kỹ thuật nghiệm thu.'
                              : 'Chưa có mẫu kiểm tra cấu hình.'),
                      style: AppTextStyles.caption.copyWith(
                        color: requiredMissing > 0
                            ? AppColors.warning
                            : AppColors.textSecondary,
                        fontWeight: requiredMissing > 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (total > 0)
                TextButton(
                  onPressed: isSaving ? null : onSave,
                  child: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lưu checklist'),
                ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: AppDimens.spacingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completedCount == total
                      ? AppColors.primary
                      : AppColors.warning,
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: AppDimens.spacingSm),
            for (var i = 0; i < checklist.length; i++) ...[
              _ChecklistTile(
                item: checklist[i],
                onChanged: (val) => onItemChanged(i, val),
              ),
              if (i < checklist.length - 1)
                const Divider(height: 1, color: AppColors.divider),
            ],
          ],
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.item,
    required this.onChanged,
  });

  final Map<String, dynamic> item;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isRequired = item['is_required'] == true;
    final completed = item['completed'] == true;

    return InkWell(
      onTap: () => onChanged(!completed),
      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.spacingSm,
          horizontal: AppDimens.spacingXs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: completed,
                activeColor: AppColors.primary,
                onChanged: (val) => onChanged(val == true),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: AppDimens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title']?.toString() ?? '',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: completed
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusSm),
                          ),
                          child: Text(
                            'Bắt buộc',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item['description'] != null &&
                      item['description'].toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item['description'].toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
