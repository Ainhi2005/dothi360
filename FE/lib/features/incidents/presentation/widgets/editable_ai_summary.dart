import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class EditableAiSummary extends StatefulWidget {
  const EditableAiSummary({
    required this.value,
    required this.onSaved,
    super.key,
  });

  final String value;
  final ValueChanged<String> onSaved;

  @override
  State<EditableAiSummary> createState() => _EditableAiSummaryState();
}

class _EditableAiSummaryState extends State<EditableAiSummary> {
  late final TextEditingController _controller;
  bool _editing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant EditableAiSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _cancel() {
    _controller.text = widget.value;
    setState(() {
      _editing = false;
      _error = null;
    });
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.length < 5) {
      setState(() => _error = 'Nội dung cần ít nhất 5 ký tự.');
      return;
    }
    widget.onSaved(value);
    setState(() {
      _editing = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              widget.value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.spacingXs),
          IconButton(
            onPressed: () => setState(() => _editing = true),
            tooltip: 'Chỉnh lại nội dung AI',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.primary,
              size: AppDimens.iconSizeSm,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: InputDecoration(
            labelText: 'Nội dung bạn xác nhận',
            hintText: 'Chỉnh lại nếu AI hiểu chưa đúng hiện trường',
            errorText: _error,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppDimens.spacingXs),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: _cancel, child: const Text('Hủy')),
            const SizedBox(width: AppDimens.spacingXs),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Lưu chỉnh sửa'),
            ),
          ],
        ),
      ],
    );
  }
}
