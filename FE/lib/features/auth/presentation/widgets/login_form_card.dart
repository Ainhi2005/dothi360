import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_auth_button.dart';
import '../../../../core/widgets/app_auth_text_field.dart';

class LoginFormCard extends StatelessWidget {
  const LoginFormCard(
      {required this.emailController,
      required this.passwordController,
      required this.isLoading,
      required this.onLogin,
      required this.onForgotPassword,
      required this.onRegister,
      super.key});
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;
  @override
  Widget build(BuildContext context) => AutofillGroup(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Chào mừng trở lại!', style: AppTextStyles.authHeading),
          const SizedBox(height: AppDimens.spacingSm),
          const Text('Đăng nhập để tiếp tục sử dụng ĐÔ THỊ 360.',
              style: AppTextStyles.authBody),
          const SizedBox(height: AppDimens.spacingLg),
          AppAuthTextField(
              hint: 'Email',
              icon: Icons.mail_outline,
              controller: emailController,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username]),
          const SizedBox(height: AppDimens.spacingBase),
          AppAuthTextField(
              hint: 'Mật khẩu',
              icon: Icons.lock_outline,
              controller: passwordController,
              enabled: !isLoading,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) {
                if (!isLoading) onLogin();
              }),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: isLoading ? null : onForgotPassword,
                  child: const Text('Quên mật khẩu?',
                      style: AppTextStyles.authLink))),
          const SizedBox(height: AppDimens.spacingSm),
          AppAuthButton(
              label: 'Đăng nhập',
              icon: Icons.arrow_forward_rounded,
              isLoading: isLoading,
              onPressed: onLogin),
          const SizedBox(height: AppDimens.spacingMd),
          Row(children: [
            const Expanded(child: Divider(color: AppColors.authBorder)),
            Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingBase),
                child: Text('hoặc',
                    style: AppTextStyles.authBody
                        .copyWith(color: AppColors.textSecondary))),
            const Expanded(child: Divider(color: AppColors.authBorder))
          ]),
          const SizedBox(height: AppDimens.spacingMd),
          AppAuthButton(
              label: 'Tạo tài khoản mới',
              icon: Icons.person_add_alt_outlined,
              outlined: true,
              onPressed: isLoading ? null : onRegister),
        ],
      ));
}
