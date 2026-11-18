import 'package:flutter/material.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_auth_text_field.dart';
import '../../../../core/widgets/app_auth_button.dart';
import 'register_consent.dart';

class RegisterFormCard extends StatelessWidget {
  const RegisterFormCard(
      {required this.name,
      required this.email,
      required this.phone,
      required this.password,
      required this.confirmPassword,
      required this.isLoading,
      required this.accepted,
      required this.onConsentChanged,
      required this.onPolicy,
      required this.onSubmit,
      super.key});
  final TextEditingController name, email, phone, password, confirmPassword;
  final bool isLoading, accepted;
  final ValueChanged<bool> onConsentChanged;
  final VoidCallback onPolicy, onSubmit;
  @override
  Widget build(BuildContext context) => AutofillGroup(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Tạo tài khoản ĐÔ THỊ 360',
              textAlign: TextAlign.center,
              style: AppTextStyles.authRegisterHeading),
          const SizedBox(height: AppDimens.spacingSm),
          const Text(
              'Tham gia cùng cộng đồng, góp phần\nxây dựng Hà Nội xanh – sạch – đẹp.',
              textAlign: TextAlign.center,
              style: AppTextStyles.authBody),
          const SizedBox(height: AppDimens.spacingMd),
          AppAuthTextField(
              hint: 'Họ và tên',
              icon: Icons.person_outline,
              controller: name,
              enabled: !isLoading,
              autofillHints: const [AutofillHints.name]),
          const SizedBox(height: AppDimens.spacingBase),
          AppAuthTextField(
              hint: 'Email',
              icon: Icons.mail_outline,
              controller: email,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email]),
          const SizedBox(height: AppDimens.spacingBase),
          AppAuthTextField(
              hint: 'Số điện thoại',
              icon: Icons.phone_outlined,
              controller: phone,
              enabled: !isLoading,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber]),
          const SizedBox(height: AppDimens.spacingBase),
          AppAuthTextField(
              hint: 'Mật khẩu',
              icon: Icons.lock_outline,
              controller: password,
              enabled: !isLoading,
              isPassword: true,
              autofillHints: const [AutofillHints.newPassword]),
          const SizedBox(height: AppDimens.spacingBase),
          AppAuthTextField(
              hint: 'Xác nhận mật khẩu',
              icon: Icons.lock_outline,
              controller: confirmPassword,
              enabled: !isLoading,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!isLoading) onSubmit();
              }),
          const SizedBox(height: AppDimens.spacingBase),
          RegisterConsent(
              accepted: accepted,
              onChanged: onConsentChanged,
              onOpenPolicy: onPolicy),
          const SizedBox(height: AppDimens.spacingMd),
          AppAuthButton(
              label: 'Đăng ký', onPressed: onSubmit, isLoading: isLoading),
        ],
      ));
}
