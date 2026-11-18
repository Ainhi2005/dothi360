import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Liên hệ hỗ trợ', style: AppTextStyles.titleMedium),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.spacingLg),
        children: [
          _ContactCard(
              icon: Icons.phone, title: 'Hotline 24/7', detail: '1900 1234'),
          const SizedBox(height: AppDimens.spacingMd),
          _ContactCard(
              icon: Icons.email,
              title: 'Email hỗ trợ',
              detail: 'hotro@dothi360.vn'),
          const SizedBox(height: AppDimens.spacingMd),
          _ContactCard(
              icon: Icons.public,
              title: 'Cổng thông tin',
              detail: 'dothi360.vn'),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _ContactCard(
      {required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: detail));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép thông tin liên hệ')));
          }
        },
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.spacingLg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.spacingSm),
                decoration: const BoxDecoration(
                    color: AppColors.primaryLight, shape: BoxShape.circle),
                child: Icon(icon,
                    color: AppColors.primary, size: AppDimens.iconSizeLg),
              ),
              const SizedBox(width: AppDimens.spacingLg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppDimens.spacingXs),
                  Text(detail,
                      style: AppTextStyles.titleMedium
                          .copyWith(color: AppColors.primary)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.copy_outlined, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
}
