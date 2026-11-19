import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/token_storage.dart';
import '../../../../core/routing/app_routes.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newController.text.length < 6 || _newController.text.length > 128) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mật khẩu mới phải từ 6 đến 128 ký tự')));
      return;
    }
    if (_newController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xác nhận mật khẩu chưa khớp')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await DioClient().dio.patch('/auth/password', data: {
        'current_password': _currentController.text,
        'new_password': _newController.text,
      });
      await TokenStorage().deleteToken();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đổi mật khẩu thành công. Vui lòng đăng nhập lại.'),
            backgroundColor: AppColors.success),
      );
      context.go(AppRoutes.login);
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.response?.data['message']?.toString() ??
                'Không thể đổi mật khẩu'),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đổi mật khẩu',
            style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spacingLg),
        child: Column(
          children: [
            const SizedBox(height: AppDimens.spacingLg),
            AppTextField(
              label: 'Mật khẩu hiện tại',
              hintText: 'Nhập mật khẩu hiện tại',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              controller: _currentController,
            ),
            const SizedBox(height: AppDimens.spacingLg),
            AppTextField(
              label: 'Mật khẩu mới',
              hintText: 'Nhập mật khẩu mới',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              controller: _newController,
            ),
            const SizedBox(height: AppDimens.spacingLg),
            AppTextField(
              label: 'Xác nhận mật khẩu mới',
              hintText: 'Nhập lại mật khẩu mới',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              controller: _confirmController,
            ),
            const SizedBox(height: AppDimens.spacingXxl),
            AppButton(
              label: 'Cập nhật mật khẩu',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
