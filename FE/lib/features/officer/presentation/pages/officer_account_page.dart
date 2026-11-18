import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../users/presentation/providers/user_profile_provider.dart';
import '../../../users/presentation/widgets/account_section.dart';
import '../../../users/presentation/widgets/account_setting_tile.dart';
import '../../../users/presentation/widgets/profile_header.dart';
import '../../../users/presentation/widgets/profile_stats.dart';
import '../providers/officer_provider.dart';

class OfficerAccountPage extends ConsumerStatefulWidget {
  const OfficerAccountPage({super.key});

  @override
  ConsumerState<OfficerAccountPage> createState() => _OfficerAccountPageState();
}

class _OfficerAccountPageState extends ConsumerState<OfficerAccountPage> {
  bool notificationsEnabled = true;

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn kết thúc phiên làm việc?'),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => dialogContext.pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.login);
  }

  Future<void> refresh() async {
    ref.invalidate(userProfileProvider);
    ref.invalidate(officerDashboardProvider);
    await Future.wait([
      ref.read(userProfileProvider.future),
      ref.read(officerDashboardProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final dashboard = ref.watch(officerDashboardProvider);
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
        onRefresh: refresh,
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
            dashboard.when(
              data: (summary) => ProfileStats(
                total: summary.mine + summary.completed,
                resolved: summary.completed,
                totalLabel: 'Công việc đã nhận',
                resolvedLabel: 'Đã hoàn thành',
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppDimens.spacingLg),
            profile.when(
              data: (user) => AccountSection(
                title: 'Đơn vị công tác',
                children: [
                  AccountSettingTile(
                    assetPath: AppAssets.interestedArea,
                    title: user.departmentName ?? 'Chưa được gán đơn vị',
                    subtitle: 'Cán bộ xử lý · Phụ trách theo địa bàn đơn vị',
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            AccountSection(
              title: 'Thông tin và bảo mật',
              children: [
                AccountSettingTile(
                  assetPath: AppAssets.accountPersonalInfo,
                  title: 'Thông tin cá nhân',
                  subtitle: 'Họ tên, email, số điện thoại',
                  onTap: () => context.push(AppRoutes.personalInfo),
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.divider,
                ),
                AccountSettingTile(
                  assetPath: AppAssets.accountPassword,
                  title: 'Đổi mật khẩu',
                  onTap: () => context.push(AppRoutes.changePassword),
                ),
              ],
            ),
            AccountSection(
              title: 'Công việc',
              children: [
                AccountSettingTile(
                  assetPath: AppAssets.accountNotification,
                  title: 'Thông báo công việc',
                  trailing: Switch(
                    value: notificationsEnabled,
                    activeTrackColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (value) =>
                        setState(() => notificationsEnabled = value),
                  ),
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.divider,
                ),
                AccountSettingTile(
                  assetPath: AppAssets.accountPermission,
                  title: 'Quyền vị trí & camera',
                  subtitle: 'Dùng khi cập nhật hiện trường',
                  onTap: Geolocator.openAppSettings,
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.divider,
                ),
                AccountSettingTile(
                  assetPath: AppAssets.profile,
                  title: 'Lịch sử xử lý',
                  subtitle: 'Các nhiệm vụ đã tiếp nhận & hoàn thành',
                  onTap: () => context.push(AppRoutes.officerHistory),
                ),
              ],
            ),
            AccountSection(
              title: 'Hỗ trợ',
              children: [
                AccountSettingTile(
                  assetPath: AppAssets.accountEmergencyGuide,
                  title: 'Hướng dẫn nghiệp vụ khẩn cấp',
                  onTap: () => context.push(AppRoutes.guide),
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.divider,
                ),
                AccountSettingTile(
                  assetPath: AppAssets.accountPrivacy,
                  title: 'Chính sách quyền riêng tư',
                  onTap: () => context.push(AppRoutes.privacy),
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.divider,
                ),
                AccountSettingTile(
                  assetPath: AppAssets.accountSupport,
                  title: 'Liên hệ hỗ trợ kỹ thuật',
                  onTap: () => context.push(AppRoutes.contact),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spacingSm),
            AppButton(
              label: 'Đăng xuất',
              icon: Icons.logout_rounded,
              type: AppButtonType.danger,
              onPressed: logout,
            ),
            const SizedBox(height: AppDimens.spacingMd),
            const Center(
              child: Text(
                'Phiên bản 1.0.0',
                style: AppTextStyles.bodySmall,
              ),
            ),
            const SizedBox(height: AppDimens.spacingXxl),
          ],
        ),
      ),
    );
  }
}
