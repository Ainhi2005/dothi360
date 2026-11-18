import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_auth_scaffold.dart';
import '../controllers/auth_controller.dart';
import '../widgets/register_form_card.dart';
import '../widgets/register_header_hero.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _accepted = false;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(authProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    String? error;
    if (_name.text.trim().length < 2 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim()) ||
        _password.text.length < 6) {
      error = 'Vui lòng nhập đúng họ tên, email và mật khẩu từ 6 ký tự.';
    } else if (_password.text != _confirm.text) {
      error = 'Mật khẩu xác nhận chưa khớp.';
    } else if (!_accepted) {
      error = 'Vui lòng đồng ý với điều khoản và chính sách bảo mật.';
    }
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final success = await ref.read(authProvider.notifier).register(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Đăng ký thành công. Hãy đăng nhập.'
          : ref.read(authProvider).error ?? 'Đăng ký thất bại'),
      backgroundColor: success ? AppColors.success : AppColors.error,
    ));
    if (success) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    return AppAuthScaffold(
      isRegister: true,
      header: RegisterHeaderHero(onBack: () => context.go(AppRoutes.login)),
      child: RegisterFormCard(
        name: _name,
        email: _email,
        phone: _phone,
        password: _password,
        confirmPassword: _confirm,
        isLoading: loading,
        accepted: _accepted,
        onConsentChanged: (value) {
          if (!loading) setState(() => _accepted = value);
        },
        onPolicy: () => context.push(AppRoutes.privacy),
        onSubmit: _submit,
      ),
    );
  }
}
