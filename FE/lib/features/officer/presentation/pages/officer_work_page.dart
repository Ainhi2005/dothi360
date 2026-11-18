import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../providers/officer_provider.dart';
import '../widgets/officer_assignment_card.dart';
import '../widgets/officer_work_toolbar.dart';

/// Màn hình Bàn công việc của Cán bộ chuẩn format Grab UI của Người dân
class OfficerWorkPage extends ConsumerStatefulWidget {
  const OfficerWorkPage({super.key});

  @override
  ConsumerState<OfficerWorkPage> createState() => _OfficerWorkPageState();
}

class _OfficerWorkPageState extends ConsumerState<OfficerWorkPage> {
  String scope = 'queue';
  String query = '';
  String filter = 'all';
  String sort = 'priority';

  Future<void> refresh() async {
    ref.invalidate(officerDashboardProvider);
    ref.invalidate(officerAssignmentsProvider(scope));
    ref.invalidate(officerUnreadNotificationsProvider);
    await Future.wait([
      ref.read(officerDashboardProvider.future),
      ref.read(officerAssignmentsProvider(scope).future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(officerAssignmentsProvider(scope));
    final dashboard = ref.watch(officerDashboardProvider);
    final unreadNotifications =
        ref.watch(officerUnreadNotificationsProvider).value ?? 0;

    final queueCount = dashboard.value?.queue ?? 0;
    final mineCount = dashboard.value?.mine ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bàn công việc',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Tiếp nhận & xử lý theo mức độ ưu tiên',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Thông báo công việc',
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text(
                unreadNotifications > 99 ? '99+' : '$unreadNotifications',
              ),
              backgroundColor: AppColors.error,
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: refresh,
            icon:
                const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: CustomScrollView(
          slivers: [
            // Thanh công cụ lọc & tab phạm vi
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.spacingBase,
                AppDimens.spacingSm,
                AppDimens.spacingBase,
                AppDimens.spacingSm,
              ),
              sliver: SliverToBoxAdapter(
                child: OfficerWorkToolbar(
                  scope: scope,
                  filter: filter,
                  queueCount: queueCount,
                  mineCount: mineCount,
                  onScopeChanged: (value) => setState(() => scope = value),
                  onFilterChanged: (value) => setState(() => filter = value),
                  onSearchChanged: (value) =>
                      setState(() => query = value.trim().toLowerCase()),
                  sort: sort,
                  onSortChanged: (value) => setState(() => sort = value),
                ),
              ),
            ),

            // Danh sách nhiệm vụ
            assignments.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.grabGreen,
                  ),
                ),
              ),
              error: (_, __) => SliverFillRemaining(
                child: Center(
                  child: AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Không thể tải danh sách',
                    description: 'Vui lòng kiểm tra kết nối mạng và thử lại.',
                    action: TextButton.icon(
                      onPressed: () =>
                          ref.invalidate(officerAssignmentsProvider(scope)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ),
                ),
              ),
              data: (items) {
                final filtered = items.where((item) {
                  final matchesQuery = query.isEmpty ||
                      item.incidentTypeName.toLowerCase().contains(query) ||
                      item.description.toLowerCase().contains(query);
                  final matchesPriority = switch (filter) {
                    'urgent' => item.isUrgent,
                    'overdue' => item.isOverdue,
                    _ => true,
                  };
                  return matchesQuery && matchesPriority;
                }).toList()
                  ..sort((a, b) => switch (sort) {
                        'distance' => (a.distanceM ?? double.infinity)
                            .compareTo(b.distanceM ?? double.infinity),
                        'sla' => (a.slaDeadline ?? DateTime(2100))
                            .compareTo(b.slaDeadline ?? DateTime(2100)),
                        _ => (b.priorityScore ?? 0)
                            .compareTo(a.priorityScore ?? 0),
                      });

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.spacingBase),
                      child: AppEmptyState(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'Danh sách hiện đã xử lý hết',
                        description: scope == 'queue'
                            ? 'Không có sự cố nào đang chờ tiếp nhận.'
                            : (scope == 'mine'
                                ? 'Bạn không có nhiệm vụ nào đang thụ lý.'
                                : 'Chưa có sự cố nào trong lịch sử.'),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.spacingBase,
                    0,
                    AppDimens.spacingBase,
                    AppDimens.spacingXl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppDimens.spacingSm),
                          child: OfficerAssignmentCard(
                            assignment: item,
                            onTap: () => context.push(
                              AppRoutes.officerAssignmentPath(item.id),
                              extra: item,
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
