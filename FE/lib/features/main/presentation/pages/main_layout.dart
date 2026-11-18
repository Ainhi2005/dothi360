import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../incidents/presentation/providers/incident_history_provider.dart';
import '../widgets/create_report_nav_item.dart';

/// Layout chính bao gồm Bottom Navigation Bar chuẩn format Grab
class MainLayout extends ConsumerWidget {
  const MainLayout({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(incidentHistoryProvider);
    final activeCount = historyAsync.maybeWhen(
      data: (list) {
        final active = list
            .where(
              (e) => !{'RESOLVED', 'REJECTED', 'CANCELLED'}.contains(e.status),
            )
            .length;
        return active > 0 ? active : null;
      },
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
            _NavItem(
              navigationShell: navigationShell,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Trang chủ',
              index: 0,
            ),
            _NavItem(
              navigationShell: navigationShell,
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore_rounded,
              label: 'Khám phá',
              index: 1,
            ),
            CreateReportNavItem(
              onTap: () => context.push(AppRoutes.createReport),
            ),
            _NavItem(
              navigationShell: navigationShell,
              icon: Icons.history_outlined,
              activeIcon: Icons.history_rounded,
              label: 'Lịch sử',
              badgeCount: activeCount,
              index: 2,
            ),
            _NavItem(
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

class _NavItem extends StatelessWidget {
  const _NavItem({
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
