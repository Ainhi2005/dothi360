import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class AssignmentRejection {
  const AssignmentRejection({required this.code, required this.reason});
  final String code;
  final String reason;
}

class RejectAssignmentSheet extends StatefulWidget {
  const RejectAssignmentSheet({super.key});

  @override
  State<RejectAssignmentSheet> createState() => _RejectAssignmentSheetState();
}

class _RejectAssignmentSheetState extends State<RejectAssignmentSheet> {
  static const _reasons = <String, String>{
    'OUT_OF_SCOPE': 'Không thuộc phạm vi chuyên môn',
    'WRONG_LOCATION': 'Sai vị trí hoặc địa bàn',
    'LACK_RESOURCES': 'Thiếu nhân lực hoặc thiết bị',
    'SAFETY_RISK': 'Không bảo đảm an toàn tiếp cận',
    'ALREADY_RESOLVED': 'Sự cố đã được xử lý',
    'OTHER': 'Lý do khác',
  };

  final _controller = TextEditingController();
  String _code = _reasons.keys.first;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.length < 5) {
      setState(() => _error = 'Vui lòng mô tả lý do ít nhất 5 ký tự.');
      return;
    }
    context.pop(AssignmentRejection(code: _code, reason: reason));
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimens.spacingMd,
          AppDimens.spacingLg,
          AppDimens.spacingMd,
          MediaQuery.viewInsetsOf(context).bottom + AppDimens.spacingMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Từ chối tiếp nhận', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppDimens.spacingXs),
            Text(
              'Hồ sơ sẽ trở về hàng chờ để admin điều phối đơn vị phù hợp hơn.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.spacingMd),
            DropdownButtonFormField<String>(
              initialValue: _code,
              decoration: const InputDecoration(labelText: 'Nhóm lý do'),
              items: _reasons.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _code = value ?? _code),
            ),
            const SizedBox(height: AppDimens.spacingMd),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: 'Lý do cụ thể *',
                hintText: 'Mô tả để điều phối viên chọn đúng đơn vị tiếp theo',
                errorText: _error,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppDimens.spacingSm),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Quay lại'),
                ),
              ),
              const SizedBox(width: AppDimens.spacingSm),
              Expanded(
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: const Text('Xác nhận từ chối'),
                ),
              ),
            ]),
          ],
        ),
      );
}
