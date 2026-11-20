import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/incident_status.dart';
import '../../data/models/officer_assignment_model.dart';
import '../../data/datasources/officer_remote_datasource.dart';

/// Giữ trạng thái biểu mẫu và điều phối nghiệp vụ; UI cung cấp phản hồi/điều hướng.
class OfficerUpdateStatusController extends ChangeNotifier {
  OfficerUpdateStatusController(
      {required this.assignment,
      required OfficerRemoteDataSource source,
      required this.onMessage,
      required this.confirmChecklist,
      required this.onSaved,
      required this.onNavigate})
      : _source = source {
    final options = availableStatuses;
    status = options.isEmpty ? null : options.first;
    progressPercent = assignment.progressPercent ?? 25;
  }
  final OfficerAssignmentModel assignment;
  final OfficerRemoteDataSource _source;
  final void Function(String message, bool isError) onMessage;
  final Future<bool> Function(int missingRequired) confirmChecklist;
  final VoidCallback onSaved;
  final VoidCallback onNavigate;
  bool _disposed = false;
  bool get mounted => !_disposed;

  void change(VoidCallback update) {
    if (_disposed) return;
    update();
    notifyListeners();
  }

  final noteController = TextEditingController();
  final blockerController = TextEditingController();
  String? status;
  String inProgressAction = 'progress';
  final List<File> evidence = [];
  int progressPercent = 25;
  DateTime? estimatedCompletionAt;
  bool isPublicUpdate = true;
  bool loading = false;

  List<String> get availableStatuses =>
      IncidentStatus.officerNextStatuses(assignment.status);

  Future<void> loadDraft() async {
    try {
      final draft = await _source.readDraft(assignment.incidentId);
      if (draft != null && mounted) {
        change(() {
          if (draft['progress_percent'] != null) {
            progressPercent = (draft['progress_percent'] as num).toInt();
          }
          if (draft['note'] != null && (draft['note'] as String).isNotEmpty) {
            noteController.text = draft['note'] as String;
          }
          if (draft['blocker'] != null &&
              (draft['blocker'] as String).isNotEmpty) {
            blockerController.text = draft['blocker'] as String;
          }
          if (draft['estimated_completion_at'] != null) {
            estimatedCompletionAt =
                DateTime.tryParse(draft['estimated_completion_at'] as String);
          }
          if (draft['is_public'] != null) {
            isPublicUpdate = draft['is_public'] as bool;
          }
          if (draft['in_progress_action'] != null) {
            inProgressAction = draft['in_progress_action'] as String;
          }
        });
        onMessage('Đã khôi phục bản nháp (Mức độ: $progressPercent%)', false);
      }
    } catch (_) {}
  }

  Future<void> saveDraft({bool showFeedback = false}) async {
    try {
      await _source.saveDraft(
        assignment.incidentId,
        {
          'incident_id': assignment.incidentId,
          'progress_percent': progressPercent,
          'note': noteController.text.trim(),
          'blocker': blockerController.text.trim(),
          'estimated_completion_at':
              estimatedCompletionAt?.toUtc().toIso8601String(),
          'is_public': isPublicUpdate,
          'in_progress_action': inProgressAction,
          'saved_at': DateTime.now().toIso8601String(),
        },
      );
      if (showFeedback && mounted) {
        onMessage('Đã lưu bản nháp tiến độ (Mức độ: $progressPercent%)', false);
      }
    } catch (_) {
      if (showFeedback && mounted) {
        onMessage('Không thể lưu bản nháp lúc này', false);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    noteController.dispose();
    blockerController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (loading || !mounted) return;
    final isProgressUpdate = assignment.status == IncidentStatus.inProgress &&
        inProgressAction == 'progress';

    if (noteController.text.trim().isEmpty) {
      onMessage('Vui lòng nhập ghi chú xử lý', false);
      return;
    }
    if (noteController.text.trim().length < 3) {
      onMessage('Ghi chú xử lý phải có ít nhất 3 ký tự', false);
      return;
    }
    if (!isProgressUpdate && status == null) {
      onMessage('Vui lòng chọn trạng thái tiếp theo', false);
      return;
    }
    if (!isProgressUpdate &&
        status == IncidentStatus.pendingVerification &&
        evidence.isEmpty) {
      onMessage('Gửi nghiệm thu cần ít nhất một ảnh minh chứng', false);
      return;
    }
    if (!isProgressUpdate && status == IncidentStatus.pendingVerification) {
      // 1. Kiểm tra checklist bắt buộc trước khi nộp nghiệm thu
      try {
        final checklist = await _source.getChecklist(assignment.incidentId);
        final missingRequired = checklist
            .where((x) => x['is_required'] == true && x['completed'] != true)
            .length;
        if (missingRequired > 0 && mounted) {
          final proceed = await confirmChecklist(missingRequired);
          if (proceed != true) return;
        }
      } catch (_) {
        // Không làm gián đoạn nghiệp vụ nếu không tải được checklist
      }
    }
    if (loading || !mounted) return;
    change(() => loading = true);
    try {
      final source = _source;
      final urls = await Future.wait(
        evidence.map((file) => source.uploadEvidence(file.path)),
      );
      if (isProgressUpdate) {
        await source.addProgress(
          incidentId: assignment.incidentId,
          note: noteController.text.trim(),
          progressPercent: progressPercent,
          estimatedCompletionAt: estimatedCompletionAt,
          blocker: blockerController.text,
          isPublic: isPublicUpdate,
          mediaUrls: urls,
        );
      } else {
        await source.updateStatus(
          incidentId: assignment.incidentId,
          status: status!,
          note: noteController.text.trim(),
          mediaUrls: urls,
        );
      }
      await _source.clearDraft(assignment.incidentId);
      onSaved();
      if (!mounted) return;
      onMessage(
          isProgressUpdate
              ? 'Đã đăng cập nhật tiến độ'
              : 'Đã cập nhật trạng thái',
          false);
      onNavigate();
    } on DioException catch (dioErr) {
      if (dioErr.response != null) {
        String serverMessage = 'Lỗi cập nhật (${dioErr.response?.statusCode})';
        final data = dioErr.response?.data;
        if (data is Map) {
          if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
            final errorList = (data['errors'] as List)
                .map((e) => e is Map ? e['message']?.toString() : null)
                .where((m) => m != null && m.isNotEmpty)
                .toList();
            if (errorList.isNotEmpty) {
              serverMessage = errorList.join('\n');
            } else if (data['message'] != null) {
              serverMessage = data['message'].toString();
            }
          } else if (data['message'] != null) {
            serverMessage = data['message'].toString();
          }
        }
        if (mounted) {
          onMessage(serverMessage, true);
        }
      } else {
        await _source.queueProgress({
          'action': isProgressUpdate ? 'progress' : 'status',
          'incident_id': assignment.incidentId,
          'note': noteController.text.trim(),
          'status': status,
          'progress_percent': progressPercent,
          'is_public': isPublicUpdate,
          'blocker': blockerController.text.trim(),
          'estimated_completion_at': estimatedCompletionAt?.toIso8601String(),
          'local_paths': evidence.map((file) => file.path).toList(),
          'created_at': DateTime.now().toIso8601String(),
        });
        if (mounted) {
          onMessage('Mất kết nối · Đã lưu vào hàng đợi đồng bộ', false);
          onNavigate();
        }
      }
    } catch (error) {
      if (mounted) {
        onMessage('$error', false);
      }
    } finally {
      if (mounted) change(() => loading = false);
    }
  }
}
