import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../incidents/presentation/providers/incident_history_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/account_section.dart';
import '../widgets/account_setting_tile.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  bool _notificationsEnabled = true;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn kết thúc phiên đăng nhập?'),
        actions: [
          TextButton(
              onPressed: () => dialogContext.pop(false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => dialogContext.pop(true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final reports = ref.watch(incidentHistoryProvider).value ?? const [];
    final resolved = reports.where((item) => item.status == 'RESOLVED').length;
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.homeCanvas,
        surfaceTintColor: AppColors.homeCanvas,
        title: Text(
          'Tài khoản',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.homeNavy,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(incidentHistoryProvider);
          await ref.read(userProfileProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.spacingMd),
          children: [
            profile.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: TextButton.icon(
                  onPressed: () => ref.invalidate(userProfileProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại thông tin'),
                ),
              ),
              data: (user) => ProfileHeader(
                fullName: user.fullName,
                email: user.email,
                phone: user.phone,
                onEditPressed: () => context.push(AppRoutes.personalInfo),
              ),
            ),
            const SizedBox(height: AppDimens.spacingBase),
            ProfileStats(total: reports.length, resolved: resolved),
            const SizedBox(height: AppDimens.spacingLg),
            AccountSection(title: 'Thông tin và bảo mật', children: [
              AccountSettingTile(
                assetPath: AppAssets.accountPersonalInfo,
                title: 'Thông tin cá nhân',
                subtitle: 'Họ tên, email, số điện thoại',
                onTap: () => context.push(AppRoutes.personalInfo),
              ),
              const Divider(height: 1, indent: 56, color: AppColors.divider),
              AccountSettingTile(
                  assetPath: AppAssets.accountPassword,
                  title: 'Đổi mật khẩu',
                  onTap: () => context.push(AppRoutes.changePassword)),
            ]),
            AccountSection(title: 'Tùy chọn', children: [
              AccountSettingTile(
                assetPath: AppAssets.accountNotification,
                title: 'Thông báo',
                trailing: Switch(
                  value: _notificationsEnabled,
                  activeTrackColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) =>
                      setState(() => _notificationsEnabled = value),
                ),
              ),
              const Divider(height: 1, indent: 56, color: AppColors.divider),
              AccountSettingTile(
                  assetPath: AppAssets.accountPermission,
                  title: 'Quyền vị trí & camera',
                  onTap: Geolocator.openAppSettings),
              const Divider(height: 1, indent: 56, color: AppColors.divider),
              AccountSettingTile(
                assetPath: AppAssets.accountLanguage,
                title: 'Ngôn ngữ',
                trailingText: 'Tiếng Việt',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Ứng dụng hiện hỗ trợ Tiếng Việt.'))),
              ),
            ]),
            AccountSection(title: 'Hỗ trợ', children: [
              AccountSettingTile(
                  assetPath: AppAssets.accountAiAssistant,
                  title: 'Trợ lý đô thị AI',
                  subtitle: 'Tra cứu phản ánh bằng hội thoại',
                  onTap: () => context.push(AppRoutes.chat)),
              const Divider(height: 1, indent: 56, color: AppColors.divider),
              AccountSettingTile(
                  assetPath: AppAssets.accountEmergencyGuide,
                  title: 'Hướng dẫn khẩn cấp',
                  onTap: () => context.push(AppRoutes.guide)),
              const Divider(height: 1, indent: 56, color: AppColors.divider),
              AccountSettingTile(
                  assetPath: AppAssets.accountPrivacy,
                  title: 'Chính sách quyền riêng tư',
                  onTap: () => context.push(AppRoutes.privacy)),
              const Divider(height: 1, indent: 56, color: AppColors.divider),
              AccountSettingTile(
                  assetPath: AppAssets.accountSupport,
                  title: 'Liên hệ hỗ trợ',
                  onTap: () => context.push(AppRoutes.contact)),
            ]),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.errorBorder),
                minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spacingMd),
            const Center(
                child: Text('Phiên bản 1.0.0', style: AppTextStyles.bodySmall)),
            const SizedBox(height: AppDimens.spacingXxl),
          ],
        ),
      ),
    );
  }
}
