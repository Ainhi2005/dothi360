import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/user_profile_provider.dart';

class PersonalInfoPage extends ConsumerStatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  ConsumerState<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends ConsumerState<PersonalInfoPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final user = profile.value;
    if (user != null && !_initialized) {
      _initialized = true;
      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông tin cá nhân',
            style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppDimens.spacingLg),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.person,
                      size: 60, color: AppColors.primary),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 16),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spacingXxl),
            AppTextField(
              label: 'Họ và tên',
              hintText: 'Nhập họ và tên',
              prefixIcon: Icons.person_outline,
              controller: _nameController,
            ),
            const SizedBox(height: AppDimens.spacingLg),
            AppTextField(
              label: 'Email',
              hintText: 'Email tài khoản',
              prefixIcon: Icons.mail_outline,
              controller: _emailController,
              readOnly: true,
            ),
            const SizedBox(height: AppDimens.spacingLg),
            AppTextField(
              label: 'Số điện thoại',
              hintText: 'Nhập số điện thoại',
              prefixIcon: Icons.phone_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppDimens.spacingXxl),
            AppButton(
              label: 'Lưu thay đổi',
              isLoading: profile.isLoading,
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Họ tên phải có ít nhất 2 ký tự')),
                  );
                  return;
                }
                final success =
                    await ref.read(userProfileProvider.notifier).updateProfile(
                          fullName: name,
                          phone: _phoneController.text.trim(),
                        );
                if (!context.mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Đã lưu thông tin cá nhân'),
                        backgroundColor: AppColors.success),
                  );
                  context.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Không thể lưu thông tin'),
                        backgroundColor: AppColors.error),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
