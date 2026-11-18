import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../users/presentation/providers/user_profile_provider.dart';
import '../../data/models/officer_assignment_model.dart';
import '../../data/models/officer_dashboard_model.dart';
import '../providers/officer_provider.dart';
import '../widgets/officer_assignment_card.dart';
import '../widgets/officer_hero_header.dart';
import '../widgets/officer_hero_urgent_card.dart';
import '../widgets/officer_summary_strip.dart';

/// Màn hình Tổng quan ca trực Cán bộ chuẩn format Grab UI của Người dân
class OfficerOverviewPage extends ConsumerStatefulWidget {
  const OfficerOverviewPage({super.key});

  @override
  ConsumerState<OfficerOverviewPage> createState() =>
      _OfficerOverviewPageState();
}

class _OfficerOverviewPageState extends ConsumerState<OfficerOverviewPage> {
  String? _actingAssignmentId;

  Future<void> _handleRefresh() async {
    ref.invalidate(officerDashboardProvider);
    ref.invalidate(officerAssignmentsProvider('all'));
    ref.invalidate(userProfileProvider);
    await Future.wait([
      ref.read(officerDashboardProvider.future).catchError((_) =>
          const OfficerDashboardModel(
              queue: 0, mine: 0, urgent: 0, overdue: 0, completed: 0)),
      ref
          .read(officerAssignmentsProvider('all').future)
          .catchError((_) => <OfficerAssignmentModel>[]),
      ref.read(userProfileProvider.future).catchError((e) => throw e),
    ]);
  }

  Future<void> _handleOneTapAccept(OfficerAssignmentModel task) async {
    if (_actingAssignmentId != null) return;
    setState(() => _actingAssignmentId = task.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(officerRemoteDataSourceProvider).accept(task.id);
      ref.invalidate(officerDashboardProvider);
      ref.invalidate(officerAssignmentsProvider('all'));
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Đã tiếp nhận nhiệm vụ thành công.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Không thể tiếp nhận nhiệm vụ lúc này.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actingAssignmentId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(officerDashboardProvider);
    final assignmentsAsync = ref.watch(officerAssignmentsProvider('all'));
    final userProfileAsync = ref.watch(userProfileProvider);

    final dashboard = dashboardAsync.value ??
        const OfficerDashboardModel(
          queue: 0,
          mine: 0,
          urgent: 0,
          overdue: 0,
          completed: 0,
        );

    final assignments =
        assignmentsAsync.value ?? const <OfficerAssignmentModel>[];

    final user = userProfileAsync.value;
    final officerName = user?.fullName ?? '';
    final departmentName = user?.departmentName ?? '';

    // Nhiệm vụ cần ưu tiên tiếp theo (khẩn cấp hoặc chờ nhận hoặc đang làm)
    final urgentTask = assignments
            .where((x) => x.isUrgent || x.isOverdue || x.isWaiting)
            .firstOrNull ??
        assignments.firstOrNull;

    // Các nhiệm vụ khác trong ca trực (lấy 3 việc gần nhất)
    final otherTasks = assignments
        .where((x) => x.id != urgentTask?.id && !x.isResolved)
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            // 1. Header Ca trực chuẩn Grab Gradient
            SliverToBoxAdapter(
              child: OfficerHeroHeader(
                officerName: officerName,
                departmentName: departmentName,
                pendingTasksCount: dashboard.queue + dashboard.mine,
                onRefresh: _handleRefresh,
                isOnline: !dashboardAsync.hasError,
              ),
            ),

            // 2. Nội dung chính
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.spacingBase,
                AppDimens.spacingSm,
                AppDimens.spacingBase,
                AppDimens.spacingXl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Chỉ số ca trực 4 cột (Chờ nhận, Của tôi, Khẩn cấp, Quá SLA)
                  OfficerSummaryStrip(
                    summary: dashboard,
                    onTapItem: (_) => context.go(AppRoutes.officerWork),
                  ),

                  const SizedBox(height: AppDimens.spacingBase),

                  // Tiêu đề phần: Nhiệm vụ ưu tiên
                  Text(
                    'Nhiệm vụ ưu tiên',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: AppDimens.spacingSm),

                  // Thẻ Hero Urgent Task
                  OfficerHeroUrgentCard(
                    task: urgentTask,
                    isActionLoading: _actingAssignmentId == urgentTask?.id,
                    onTapDetail: () {
                      if (urgentTask != null) {
                        context.push(
                          AppRoutes.officerAssignmentPath(urgentTask.id),
                          extra: urgentTask,
                        );
                      } else {
                        context.go(AppRoutes.officerWork);
                      }
                    },
                    onOneTapAction: () {
                      if (urgentTask == null) return;
                      if (urgentTask.isWaiting) {
                        _handleOneTapAccept(urgentTask);
                      } else {
                        context.push(
                          AppRoutes.officerUpdatePath(urgentTask.incidentId),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: AppDimens.spacingBase),

                  // Danh sách nhiệm vụ khác trong ca
                  if (otherTasks.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Công việc trong ca trực',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        InkWell(
                          onTap: () => context.go(AppRoutes.officerWork),
                          child: Text(
                            'Xem tất cả (${assignments.length})',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grabGreenDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.spacingSm),
                    for (final item in otherTasks) ...[
                      OfficerAssignmentCard(
                        assignment: item,
                        onTap: () => context.push(
                          AppRoutes.officerAssignmentPath(item.id),
                          extra: item,
                        ),
                      ),
                      const SizedBox(height: AppDimens.spacingSm),
                    ],
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
