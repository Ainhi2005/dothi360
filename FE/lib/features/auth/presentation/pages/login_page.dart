import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_auth_scaffold.dart';
import '../controllers/auth_controller.dart';
import '../widgets/login_form_card.dart';
import '../widgets/login_header_hero.dart';

/// Màn hình Đăng nhập chuẩn theo thiết kế Figma Đô thị 360 (Ảnh 1)
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    FocusScope.of(context).unfocus();
    ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    // Lắng nghe sự thay đổi trạng thái đăng nhập
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.isSuccess && (previous == null || !previous.isSuccess)) {
        // Đăng nhập thành công -> Điều hướng theo vai trò
        context.go(
          next.userRole == 'OFFICER' ? AppRoutes.officerWork : AppRoutes.home,
        );
      }
    });

    return AppAuthScaffold(
      header: const LoginHeaderHero(),
      child: LoginFormCard(
        emailController: _emailController,
        passwordController: _passwordController,
        isLoading: authState.isLoading,
        onLogin: _handleLogin,
        onForgotPassword: () => context.push(AppRoutes.forgotPassword),
        onRegister: () => context.push(AppRoutes.register),
      ),
    );
  }
}
