import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/officer_provider.dart';

/// Layout chính Cán bộ xử lý đồng bộ format Grab UI với Người dân
class OfficerLayout extends ConsumerWidget {
  const OfficerLayout({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(officerDashboardProvider);
    final waitingCount = dashboardAsync.maybeWhen(
      data: (d) => (d.queue + d.mine) > 0 ? (d.queue + d.mine) : null,
      orElse: () => null,
    );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.navBorderTop, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _OfficerNavItem(
              navigationShell: navigationShell,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Tổng quan',
              index: 0,
            ),
            _OfficerNavItem(
              navigationShell: navigationShell,
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment_rounded,
              label: 'Công việc',
              badgeCount: waitingCount,
              index: 1,
            ),
            _OfficerNavItem(
              navigationShell: navigationShell,
              icon: Icons.map_outlined,
              activeIcon: Icons.map_rounded,
              label: 'Bản đồ',
              index: 2,
            ),
            _OfficerNavItem(
              navigationShell: navigationShell,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Tài khoản',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficerNavItem extends StatelessWidget {
  const _OfficerNavItem({
    required this.navigationShell,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    this.badgeCount,
  });

  final StatefulNavigationShell navigationShell;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final isSelected = navigationShell.currentIndex == index;
    final color = isSelected ? AppColors.grabGreen : AppColors.navInactive;

    return InkWell(
      onTap: () {
        navigationShell.goBranch(index, initialLocation: isSelected);
      },
      child: SizedBox(
        width: 64,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: 8,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    badgeCount! > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
