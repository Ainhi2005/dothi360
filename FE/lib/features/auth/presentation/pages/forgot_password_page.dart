import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/routing/app_routes.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background placeholder
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.location_city,
                  size: 200,
                  color: AppColors.primary,
                ),
              ),
            ),

            // Main Content
            SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppDimens.spacingXl),

                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spacingLg),

                  // Heading
                  const Text(
                    'Quên mật khẩu?',
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: AppDimens.spacingSm),
                  const Text(
                    'Nhập email của bạn, chúng tôi sẽ gửi mã khôi phục mật khẩu.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppDimens.spacingXl),

                  // Form Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppDimens.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Email',
                          hintText: 'Nhập email của bạn',
                          prefixIcon: Icons.mail_outline,
                          controller: _emailController,
                        ),
                        const SizedBox(height: AppDimens.spacingXl),

                        // Submit Button
                        AppButton(
                          label: 'Gửi yêu cầu khôi phục',
                          onPressed: () async {
                            final email = _emailController.text.trim();
                            if (!email.contains('@')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Vui lòng nhập email hợp lệ.')),
                              );
                              return;
                            }
                            await showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Yêu cầu đã được ghi nhận'),
                                content: const Text(
                                  'Hệ thống thử nghiệm chưa tích hợp máy chủ gửi email. Vui lòng liên hệ hỗ trợ để xác minh và đặt lại mật khẩu.',
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () => dialogContext.pop(),
                                      child: const Text('Đóng')),
                                  FilledButton(
                                    onPressed: () {
                                      dialogContext.pop();
                                      context.push(AppRoutes.contact);
                                    },
                                    child: const Text('Liên hệ hỗ trợ'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.spacingXxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
