import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/constants/incident_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/officer_assignment_model.dart';
import '../providers/officer_provider.dart';
import '../widgets/officer_progress_fields.dart';

class OfficerUpdateStatusPage extends ConsumerStatefulWidget {
  const OfficerUpdateStatusPage({required this.assignment, super.key});
  final OfficerAssignmentModel assignment;

  @override
  ConsumerState<OfficerUpdateStatusPage> createState() =>
      _OfficerUpdateStatusPageState();
}

class _OfficerUpdateStatusPageState
    extends ConsumerState<OfficerUpdateStatusPage> {
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
      IncidentStatus.officerNextStatuses(widget.assignment.status);

  @override
  void initState() {
    super.initState();
    final options = availableStatuses;
    status = options.isEmpty ? null : options.first;
    if (widget.assignment.progressPercent != null) {
      progressPercent = widget.assignment.progressPercent!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDraft();
    });
  }

  Future<void> _loadDraft() async {
    try {
      final draft = await ref
          .read(officerRemoteDataSourceProvider)
          .readDraft(widget.assignment.incidentId);
      if (draft != null && mounted) {
        setState(() {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã khôi phục bản nháp (Mức độ: $progressPercent%)',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _saveDraft({bool showFeedback = false}) async {
    try {
      await ref.read(officerRemoteDataSourceProvider).saveDraft(
        widget.assignment.incidentId,
        {
          'incident_id': widget.assignment.incidentId,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Đã lưu bản nháp tiến độ (Mức độ: $progressPercent%)'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (_) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lưu bản nháp lúc này')),
        );
      }
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    blockerController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final isProgressUpdate =
        widget.assignment.status == IncidentStatus.inProgress &&
            inProgressAction == 'progress';

    if (noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập ghi chú xử lý')),
      );
      return;
    }
    if (noteController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ghi chú xử lý phải có ít nhất 3 ký tự')),
      );
      return;
    }
    if (!isProgressUpdate && status == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn trạng thái tiếp theo')),
      );
      return;
    }
    if (!isProgressUpdate &&
        status == IncidentStatus.pendingVerification &&
        evidence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gửi nghiệm thu cần ít nhất một ảnh minh chứng')));
      return;
    }
    if (!isProgressUpdate && status == IncidentStatus.pendingVerification) {
      // 1. Kiểm tra checklist bắt buộc trước khi nộp nghiệm thu
      try {
        final checklist = await ref
            .read(officerRemoteDataSourceProvider)
            .getChecklist(widget.assignment.incidentId);
        final missingRequired = checklist
            .where((x) => x['is_required'] == true && x['completed'] != true)
            .length;
        if (missingRequired > 0 && mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Cảnh báo thiếu Checklist'),
              content: Text(
                'Hiện trường còn $missingRequired mục bắt buộc trong checklist chưa đánh dấu hoàn thành.\n\nBạn có chắc chắn muốn nộp minh chứng nghiệm thu lúc này không?',
                style: AppTextStyles.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => dialogContext.pop(false),
                  child: const Text('Kiểm tra lại'),
                ),
                FilledButton(
                  onPressed: () => dialogContext.pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Vẫn nộp'),
                ),
              ],
            ),
          );
          if (proceed != true) return;
        }
      } catch (_) {
        // Không làm gián đoạn nghiệp vụ nếu không tải được checklist
      }
    }
    setState(() => loading = true);
    try {
      final source = ref.read(officerRemoteDataSourceProvider);
      final urls = await Future.wait(
        evidence.map((file) => source.uploadEvidence(file.path)),
      );
      if (isProgressUpdate) {
        await source.addProgress(
          incidentId: widget.assignment.incidentId,
          note: noteController.text.trim(),
          progressPercent: progressPercent,
          estimatedCompletionAt: estimatedCompletionAt,
          blocker: blockerController.text,
          isPublic: isPublicUpdate,
          mediaUrls: urls,
        );
      } else {
        await source.updateStatus(
          incidentId: widget.assignment.incidentId,
          status: status!,
          note: noteController.text.trim(),
          mediaUrls: urls,
        );
      }
      await ref
          .read(officerRemoteDataSourceProvider)
          .clearDraft(widget.assignment.incidentId);
      ref.invalidate(officerAssignmentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isProgressUpdate
            ? 'Đã đăng cập nhật tiến độ'
            : 'Đã cập nhật trạng thái'),
      ));
      context.go(AppRoutes.officerWork);
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(serverMessage),
            backgroundColor: AppColors.error,
          ));
        }
      } else {
        await ref.read(officerRemoteDataSourceProvider).queueProgress({
          'action': isProgressUpdate ? 'progress' : 'status',
          'incident_id': widget.assignment.incidentId,
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Mất kết nối · Đã lưu vào hàng đợi đồng bộ')));
          context.go(AppRoutes.officerWork);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật xử lý'),
        actions: [
          TextButton.icon(
            onPressed: () => _saveDraft(showFeedback: true),
            icon: const Icon(Icons.bookmark_outline, size: 18),
            label: const Text('Lưu nháp'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync_alt, color: AppColors.primary),
                const SizedBox(width: AppDimens.spacingBase),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trạng thái hiện tại',
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: AppDimens.spacingXs),
                      Text(
                        IncidentStatus.label(widget.assignment.status),
                        style: AppTextStyles.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),
          if (widget.assignment.status == IncidentStatus.inProgress) ...[
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'progress',
                    icon: Icon(Icons.update),
                    label: Text('Cập nhật tiến độ'),
                  ),
                  ButtonSegment(
                    value: 'verification',
                    icon: Icon(Icons.fact_check_outlined),
                    label: Text('Gửi nghiệm thu'),
                  ),
                ],
                selected: {inProgressAction},
                onSelectionChanged: (value) =>
                    setState(() => inProgressAction = value.first),
              ),
            ),
            const SizedBox(height: AppDimens.spacingMd),
          ],
          if (status != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimens.spacingMd),
              decoration: BoxDecoration(
                color: inProgressAction == 'verification'
                    ? AppColors.warningLight
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    inProgressAction == 'verification'
                        ? Icons.fact_check_outlined
                        : widget.assignment.status == IncidentStatus.inProgress
                            ? Icons.update
                            : Icons.play_circle_outline,
                    color: inProgressAction == 'verification'
                        ? AppColors.warning
                        : AppColors.primary,
                  ),
                  const SizedBox(width: AppDimens.spacingBase),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bước tiếp theo',
                            style: AppTextStyles.bodySmall),
                        const SizedBox(height: AppDimens.spacingXs),
                        Text(
                          widget.assignment.status ==
                                      IncidentStatus.inProgress &&
                                  inProgressAction == 'progress'
                              ? 'Báo cáo tiến độ mới'
                              : IncidentStatus.actionLabel(status!),
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: AppDimens.spacingXs),
                        Text(
                          widget.assignment.status ==
                                      IncidentStatus.inProgress &&
                                  inProgressAction == 'progress'
                              ? 'Ghi lại công việc đã làm; trạng thái vẫn là Đang xử lý.'
                              : IncidentStatus.actionDescription(status!),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimens.spacingMd),
          if (widget.assignment.aiAnalysis?['recommended_action'] != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimens.spacingSm),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: AppDimens.iconSizeSm,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppDimens.spacingXs),
                      const Expanded(
                        child: Text(
                          'AI đề xuất biện pháp xử lý:',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          final rec = widget
                              .assignment.aiAnalysis!['recommended_action']
                              .toString();
                          setState(() {
                            noteController.text = noteController.text.isEmpty
                                ? 'Đã áp dụng biện pháp: $rec'
                                : '${noteController.text}\n- Đã xử lý theo đề xuất: $rec';
                          });
                        },
                        child: const Text(
                          'Áp dụng vào ghi chú',
                          style: AppTextStyles.linkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.spacingXs),
                  Text(
                    widget.assignment.aiAnalysis!['recommended_action']
                        .toString(),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.spacingSm),
          ],
          AppTextField(
              label: 'Ghi chú xử lý',
              hintText: 'Mô tả công việc đã thực hiện',
              controller: noteController,
              maxLines: 5),
          if (widget.assignment.status == IncidentStatus.inProgress &&
              inProgressAction == 'progress') ...[
            const SizedBox(height: AppDimens.spacingMd),
            OfficerProgressFields(
              progressPercent: progressPercent,
              estimatedCompletionAt: estimatedCompletionAt,
              blockerController: blockerController,
              isPublic: isPublicUpdate,
              onProgressChanged: (value) {
                setState(() => progressPercent = value);
                _saveDraft();
              },
              onVisibilityChanged: (value) =>
                  setState(() => isPublicUpdate = value),
              onPickEta: () async {
                final value = await showDatePicker(
                  context: context,
                  initialDate: estimatedCompletionAt ??
                      DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (value != null) {
                  setState(() => estimatedCompletionAt = value);
                }
              },
            ),
          ],
          const SizedBox(height: AppDimens.spacingMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: evidence.length >= 5
                      ? null
                      : () async {
                          final image = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            setState(() => evidence.add(File(image.path)));
                          }
                        },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Chụp ảnh'),
                ),
              ),
              const SizedBox(width: AppDimens.spacingSm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: evidence.length >= 5
                      ? null
                      : () async {
                          final images = await ImagePicker().pickMultiImage(
                            imageQuality: 80,
                            limit: 5 - evidence.length,
                          );
                          if (images.isNotEmpty) {
                            setState(() => evidence.addAll(
                                  images.map((image) => File(image.path)),
                                ));
                          }
                        },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text('Thư viện (${evidence.length}/5)'),
                ),
              ),
            ],
          ),
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: AppDimens.spacingMd),
            Wrap(
              spacing: AppDimens.spacingSm,
              runSpacing: AppDimens.spacingSm,
              children: evidence
                  .map((file) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusSm),
                            child: Image.file(
                              file,
                              cacheWidth: AppDimens.mediaThumbnailDecodeWidth,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: IconButton.filled(
                              onPressed: () =>
                                  setState(() => evidence.remove(file)),
                              icon: const Icon(Icons.close,
                                  size: AppDimens.iconSizeSm),
                            ),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: AppDimens.spacingLg),
          AppButton(
              label: widget.assignment.status == IncidentStatus.inProgress
                  ? inProgressAction == 'progress'
                      ? 'Đăng cập nhật tiến độ'
                      : 'Gửi kết quả để nghiệm thu'
                  : 'Xác nhận bắt đầu xử lý',
              isLoading: loading,
              onPressed: submit),
        ],
      ),
    );
  }
}
