import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class RegisterConsent extends StatelessWidget {
  const RegisterConsent(
      {required this.accepted,
      required this.onChanged,
      required this.onOpenPolicy,
      super.key});
  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenPolicy;
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: AppDimens.minTouchTarget,
            height: AppDimens.minTouchTarget,
            child: Checkbox(
                value: accepted,
                activeColor: AppColors.primary,
                side: const BorderSide(color: AppColors.authBorder),
                onChanged: (value) => onChanged(value ?? false))),
        Expanded(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppDimens.spacingSm),
                child: Wrap(children: [
                  const Text('Tôi đồng ý với ', style: AppTextStyles.authBody),
                  InkWell(
                      onTap: onOpenPolicy,
                      child: const Text('Điều khoản sử dụng',
                          style: AppTextStyles.authLink)),
                  const Text(' và ', style: AppTextStyles.authBody),
                  InkWell(
                      onTap: onOpenPolicy,
                      child: const Text('Chính sách bảo mật',
                          style: AppTextStyles.authLink)),
                  const Text(' của ĐÔ THỊ 360.', style: AppTextStyles.authBody),
                ]))),
      ]);
}
