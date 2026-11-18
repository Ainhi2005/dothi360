import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class CheckboxNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool val) => state = val;
}

final checkbox1Provider =
    NotifierProvider<CheckboxNotifier, bool>(CheckboxNotifier.new);
final checkbox2Provider =
    NotifierProvider<CheckboxNotifier, bool>(CheckboxNotifier.new);

class ConfirmCheckboxes extends ConsumerWidget {
  const ConfirmCheckboxes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isChecked1 = ref.watch(checkbox1Provider);
    final isChecked2 = ref.watch(checkbox2Provider);

    return Column(
      children: [
        _buildCheckboxTile(
          value: isChecked1,
          label: 'Tôi xác nhận thông tin trên là đúng với hiện trường.',
          onChanged: (val) =>
              ref.read(checkbox1Provider.notifier).set(val ?? false),
        ),
        const SizedBox(height: AppDimens.spacingSm),
        _buildCheckboxTile(
          value: isChecked2,
          label: 'Tôi đồng ý chia sẻ ảnh và vị trí cho đơn vị xử lý.',
          onChanged: (val) =>
              ref.read(checkbox2Provider.notifier).set(val ?? false),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(
      {required bool value,
      required String label,
      required ValueChanged<bool?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacingSm, vertical: AppDimens.spacingXs),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
