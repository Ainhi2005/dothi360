import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/officer_assignment_model.dart';
import '../providers/officer_provider.dart';
import '../widgets/officer_incident_context_card.dart';
import '../widgets/officer_next_action_card.dart';
import '../widgets/officer_workspace_bottom_bar.dart';
import '../widgets/officer_workspace_checklist_card.dart';
import '../widgets/officer_workspace_header.dart';
import '../widgets/reject_assignment_sheet.dart';

class OfficerAssignmentDetailPage extends ConsumerStatefulWidget {
  const OfficerAssignmentDetailPage({
    required this.assignmentId,
    this.initialAssignment,
    super.key,
  });

  final String assignmentId;
  final OfficerAssignmentModel? initialAssignment;

  @override
  ConsumerState<OfficerAssignmentDetailPage> createState() =>
      _OfficerAssignmentDetailPageState();
}

class _OfficerAssignmentDetailPageState
    extends ConsumerState<OfficerAssignmentDetailPage> {
  bool _isLoading = false;
  bool _isLoadingDetail = true;
  bool _isSavingChecklist = false;
  OfficerAssignmentModel? _assignment;
  List<Map<String, dynamic>> _checklist = [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _assignment = widget.initialAssignment;
    _loadData();
  }

  Future<void> _loadData() async {
    final api = ref.read(officerRemoteDataSourceProvider);
    if (mounted) {
      setState(() {
        _loadError = null;
        _isLoadingDetail = true;
      });
    }
    try {
      final assignmentFuture = api.getAssignment(widget.assignmentId);
      final checklistFuture = _assignment != null
          ? api.getChecklist(_assignment!.incidentId)
          : assignmentFuture.then((a) => api.getChecklist(a.incidentId));

      final results = await Future.wait([
        assignmentFuture,
        checklistFuture.catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          _assignment = results[0] as OfficerAssignmentModel;
          _checklist = List<Map<String, dynamic>>.from(
            results[1] as List<dynamic>,
          );
        });
      }
    } catch (error) {
      var message = 'Không thể tải hồ sơ nhiệm vụ. Vui lòng thử lại.';
      if (error is DioException && error.response?.data is Map) {
        final serverMessage = error.response?.data['message']?.toString();
        if (serverMessage != null && serverMessage.trim().isNotEmpty) {
          message = serverMessage.trim();
        }
      } else if (error is DioException &&
          error.type == DioExceptionType.connectionError) {
        message = 'Không thể kết nối máy chủ. Hãy kiểm tra mạng và thử lại.';
      }
      if (mounted) setState(() => _loadError = message);
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _handleSaveChecklist() async {
    if (_assignment == null || !_assignment!.canAct) return;
    setState(() => _isSavingChecklist = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(officerRemoteDataSourceProvider).saveChecklist(
            _assignment!.incidentId,
            _checklist
                .map((x) => {
                      'id': x['id'],
                      'completed': x['completed'] == true,
                      'note': (x['note'] != null &&
                              x['note'].toString().trim().isNotEmpty)
                          ? x['note'].toString().trim()
                          : null,
                    })
                .toList(),
          );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã cập nhật checklist hiện trường.')),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Không thể lưu checklist lúc này.';
        if (e is DioException && e.response?.data is Map) {
          final serverMsg = e.response?.data['message']?.toString();
          if (serverMsg != null && serverMsg.trim().isNotEmpty) {
            msg = serverMsg.trim();
          }
        }
        messenger.showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingChecklist = false);
    }
  }

  Future<void> _handleAccept() async {
    if (_assignment == null || !_assignment!.canAct) return;
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(officerRemoteDataSourceProvider).accept(_assignment!.id);
      ref.invalidate(officerAssignmentsProvider);
      ref.invalidate(officerDashboardProvider);
      await _loadData();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã tiếp nhận nhiệm vụ thành công.')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Tiếp nhận thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReject() async {
    final assignment = _assignment;
    if (assignment == null) return;
    final rejection = await showModalBottomSheet<AssignmentRejection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const RejectAssignmentSheet(),
    );
    if (rejection == null || !mounted) return;
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(officerRemoteDataSourceProvider).reject(
            assignmentId: assignment.id,
            reasonCode: rejection.code,
            reason: rejection.reason,
          );
      ref.invalidate(officerAssignmentsProvider);
      ref.invalidate(officerDashboardProvider);
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Hồ sơ đã được chuyển về hàng chờ điều phối.'),
        ));
        context.go(AppRoutes.officerWork);
      }
    } catch (error) {
      if (mounted) {
        messenger
            .showSnackBar(SnackBar(content: Text('Không thể từ chối: $error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workspace nhiệm vụ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError!, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppDimens.spacingMd),
                OutlinedButton(
                  onPressed: () {
                    setState(() => _loadError = null);
                    _loadData();
                  },
                  child: const Text('Tải lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = _assignment;
    if (item == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workspace hiện trường'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.spacingMd),
          children: [
            OfficerWorkspaceHeader(assignment: item),
            const SizedBox(height: AppDimens.spacingMd),
            OfficerNextActionCard(assignment: item),
            const SizedBox(height: AppDimens.spacingMd),
            OfficerIncidentContextCard(assignment: item),
            if (item.canAct) ...[
              const SizedBox(height: AppDimens.spacingMd),
              OfficerWorkspaceChecklistCard(
                checklist: _checklist,
                isSaving: _isSavingChecklist,
                onItemChanged: (index, completed) {
                  setState(() => _checklist[index]['completed'] = completed);
                },
                onSave: _handleSaveChecklist,
              ),
            ],
            const SizedBox(height: AppDimens.spacingXl),
          ],
        ),
      ),
      bottomNavigationBar: OfficerWorkspaceBottomBar(
        assignment: item,
        isLoading: _isLoading || _isLoadingDetail,
        onAccept: _handleAccept,
        onReject: _handleReject,
        onUpdateStatus: () => context.push(
          AppRoutes.officerUpdatePath(item.incidentId),
          extra: item,
        ),
      ),
    );
  }
}
