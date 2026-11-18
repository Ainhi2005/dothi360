import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/token_storage.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/notification_model.dart';
import '../widgets/notification_date_group_header.dart';
import '../widgets/notification_empty_state.dart';
import '../widgets/notification_tile.dart';

/// Trang Thông báo dạng ngắn gọn theo mẫu thiết kế
/// - Thanh lọc phía trên: [Tất cả] và [Chưa đọc]
/// - Danh sách phân nhóm: "Mới" (kèm link "Xem tất cả") và "Trước đó"
/// - Thẻ thông báo hàng phẳng, icon tròn pastel, thời gian tương đối
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _api = NotificationRemoteDataSource();
  List<NotificationModel>? _items;
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'all'; // 'all' hoặc 'unread'

  @override
  void initState() {
    super.initState();
    _loadData();
    PushNotificationService.foregroundNotificationStream
        .addListener(_onPushReceived);
  }

  @override
  void dispose() {
    PushNotificationService.foregroundNotificationStream
        .removeListener(_onPushReceived);
    super.dispose();
  }

  void _onPushReceived() {
    if (mounted) _loadData();
  }

  Future<void> _loadData() async {
    try {
      final list = await _api.list();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải lịch sử thông báo';
      });
    }
  }

  Future<void> _handleReadAll() async {
    try {
      await _api.readAll();
      if (!mounted) return;
      setState(() {
        _items = _items?.map((e) => e.copyWith(isRead: true)).toList();
      });
    } catch (_) {}
  }

  Future<void> _handleDeleteSingle(NotificationModel item) async {
    final previousList = _items ?? [];
    setState(() {
      _items = previousList.where((e) => e.id != item.id).toList();
    });
    try {
      await _api.delete(item.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = previousList);
    }
  }

  Future<void> _confirmDeleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ thông báo?',
            style: AppTextStyles.titleMedium),
        content: const Text(
          'Hành động này sẽ xóa tất cả thông báo trong lịch sử của bạn.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Xóa tất cả', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _items = []);
      try {
        await _api.deleteAll();
      } catch (_) {
        _loadData();
      }
    }
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.badgeBlueBg : AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color:
                  isSelected ? AppColors.badgeBlueText : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _items ?? [];
    final filtered = _filter == 'unread'
        ? allItems.where((e) => !e.isRead).toList()
        : allItems;

    final newItems = filtered.where((e) => e.isNew).toList();
    final earlierItems = filtered.where((e) => !e.isNew).toList();
    final hasUnread = allItems.any((e) => !e.isRead);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Thông báo',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderSubtle),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _handleReadAll,
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(
                  color: AppColors.grabGreenDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          if (allItems.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: AppColors.textPrimary,
                size: 22,
              ),
              tooltip: 'Xóa tất cả',
              onPressed: _confirmDeleteAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!, style: AppTextStyles.bodyMedium),
                )
              : Column(
                  children: [
                    // 1. Thanh lọc Pill: [ Tất cả ] và [ Chưa đọc ]
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.spacingBase,
                        AppDimens.spacingSm,
                        AppDimens.spacingBase,
                        AppDimens.spacingSm,
                      ),
                      child: Row(
                        children: [
                          _buildFilterPill(
                            label: 'Tất cả',
                            isSelected: _filter == 'all',
                            onTap: () => setState(() => _filter = 'all'),
                          ),
                          const SizedBox(width: AppDimens.spacingSm),
                          _buildFilterPill(
                            label: 'Chưa đọc',
                            isSelected: _filter == 'unread',
                            onTap: () => setState(() => _filter = 'unread'),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: AppColors.borderSubtle),

                    // 2. Danh sách thông báo dạng ngắn gọn
                    Expanded(
                      child: filtered.isEmpty
                          ? const NotificationEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView(
                                children: [
                                  // Phần 1: Mới
                                  if (newItems.isNotEmpty) ...[
                                    NotificationDateGroupHeader(
                                      title: 'Mới',
                                      actionText:
                                          hasUnread ? 'Xem tất cả' : null,
                                      onActionTap: () => _handleReadAll(),
                                    ),
                                    for (final item in newItems) ...[
                                      NotificationTile(
                                        item: item,
                                        onTap: () async {
                                          if (!item.isRead) {
                                            _api.read(item.id);
                                            setState(() {
                                              _items = _items
                                                  ?.map((e) => e.id == item.id
                                                      ? e.copyWith(isRead: true)
                                                      : e)
                                                  .toList();
                                            });
                                          }
                                          if (!context.mounted) return;
                                          final role =
                                              await TokenStorage().getRole();
                                          if (!context.mounted) return;
                                          if (item.feedbackId?.isNotEmpty ==
                                              true) {
                                            context.push(AppRoutes.feedbacks);
                                          } else if (role == 'OFFICER' &&
                                              item.assignmentId?.isNotEmpty ==
                                                  true) {
                                            context.push(
                                              AppRoutes.officerAssignmentPath(
                                                  item.assignmentId!),
                                            );
                                          } else if (item.incidentId != null &&
                                              item.incidentId!.isNotEmpty) {
                                            context.push(
                                              AppRoutes.incidentDetailPath(
                                                  item.incidentId!),
                                            );
                                          }
                                        },
                                        onDelete: () =>
                                            _handleDeleteSingle(item),
                                      ),
                                      const Divider(
                                        height: 1,
                                        thickness: 0.6,
                                        color: AppColors.borderSubtle,
                                      ),
                                    ],
                                  ],

                                  // Phần 2: Trước đó
                                  if (earlierItems.isNotEmpty) ...[
                                    const NotificationDateGroupHeader(
                                      title: 'Trước đó',
                                    ),
                                    for (final item in earlierItems) ...[
                                      NotificationTile(
                                        item: item,
                                        onTap: () async {
                                          if (!item.isRead) {
                                            _api.read(item.id);
                                            setState(() {
                                              _items = _items
                                                  ?.map((e) => e.id == item.id
                                                      ? e.copyWith(isRead: true)
                                                      : e)
                                                  .toList();
                                            });
                                          }
                                          if (!context.mounted) return;
                                          final role =
                                              await TokenStorage().getRole();
                                          if (!context.mounted) return;
                                          if (item.feedbackId?.isNotEmpty ==
                                              true) {
                                            context.push(AppRoutes.feedbacks);
                                          } else if (role == 'OFFICER' &&
                                              item.assignmentId?.isNotEmpty ==
                                                  true) {
                                            context.push(
                                              AppRoutes.officerAssignmentPath(
                                                  item.assignmentId!),
                                            );
                                          } else if (item.incidentId != null &&
                                              item.incidentId!.isNotEmpty) {
                                            context.push(
                                              AppRoutes.incidentDetailPath(
                                                  item.incidentId!),
                                            );
                                          }
                                        },
                                        onDelete: () =>
                                            _handleDeleteSingle(item),
                                      ),
                                      const Divider(
                                        height: 1,
                                        thickness: 0.6,
                                        color: AppColors.borderSubtle,
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
