import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/constants/incident_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/officer_assignment_model.dart';
import '../providers/officer_provider.dart';
import '../controllers/officer_update_status_controller.dart';
import '../widgets/officer_checklist_dialog.dart';
import '../widgets/officer_progress_fields.dart';
import '../widgets/officer_current_status_card.dart';
import '../widgets/officer_next_action_summary.dart';
import '../widgets/officer_ai_recommendation_card.dart';
import '../widgets/officer_evidence_picker.dart';

class OfficerUpdateStatusPage extends ConsumerStatefulWidget {
  const OfficerUpdateStatusPage({required this.assignment, super.key});
  final OfficerAssignmentModel assignment;

  @override
  ConsumerState<OfficerUpdateStatusPage> createState() =>
      _OfficerUpdateStatusPageState();
}

class _OfficerUpdateStatusPageState
    extends ConsumerState<OfficerUpdateStatusPage> {
  late final OfficerUpdateStatusController controller;

  @override
  void initState() {
    super.initState();
    controller = OfficerUpdateStatusController(
      assignment: widget.assignment,
      source: ref.read(officerRemoteDataSourceProvider),
      onMessage: (message, isError) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : null,
        ));
      },
      confirmChecklist: (missing) async {
        if (!mounted) return false;
        return await showDialog<bool>(
                context: context,
                builder: (_) =>
                    OfficerChecklistDialog(missingRequired: missing)) ==
            true;
      },
      onSaved: () {
        if (mounted) ref.invalidate(officerAssignmentsProvider);
      },
      onNavigate: () {
        if (mounted) context.go(AppRoutes.officerWork);
      },
    )..addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadDraft();
    });
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onChanged);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật xử lý'),
        actions: [
          TextButton.icon(
            onPressed: () => controller.saveDraft(showFeedback: true),
            icon: const Icon(Icons.bookmark_outline, size: 18),
            label: const Text('Lưu nháp'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        children: [
          OfficerCurrentStatusCard(currentStatus: widget.assignment.status),
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
                selected: {controller.inProgressAction},
                onSelectionChanged: (value) => controller
                    .change(() => controller.inProgressAction = value.first),
              ),
            ),
            const SizedBox(height: AppDimens.spacingMd),
          ],
          if (controller.status != null) ...[
            OfficerNextActionSummary(
                currentStatus: widget.assignment.status,
                nextStatus: controller.status!,
                inProgressAction: controller.inProgressAction),
          ],
          const SizedBox(height: AppDimens.spacingMd),
          if (widget.assignment.aiAnalysis?['recommended_action'] != null) ...[
            OfficerAiRecommendationCard(
              recommendation: widget
                  .assignment.aiAnalysis!['recommended_action']
                  .toString(),
              onApply: () {
                final rec = widget.assignment.aiAnalysis!['recommended_action']
                    .toString();
                controller.change(() {
                  controller.noteController.text = controller
                          .noteController.text.isEmpty
                      ? 'Đã áp dụng biện pháp: $rec'
                      : '${controller.noteController.text}\n- Đã xử lý theo đề xuất: $rec';
                });
              },
            ),
            const SizedBox(height: AppDimens.spacingSm),
          ],
          AppTextField(
              label: 'Ghi chú xử lý',
              hintText: 'Mô tả công việc đã thực hiện',
              controller: controller.noteController,
              maxLines: 5),
          if (widget.assignment.status == IncidentStatus.inProgress &&
              controller.inProgressAction == 'progress') ...[
            const SizedBox(height: AppDimens.spacingMd),
            OfficerProgressFields(
              progressPercent: controller.progressPercent,
              estimatedCompletionAt: controller.estimatedCompletionAt,
              blockerController: controller.blockerController,
              isPublic: controller.isPublicUpdate,
              onProgressChanged: (value) {
                controller.change(() => controller.progressPercent = value);
                controller.saveDraft();
              },
              onVisibilityChanged: (value) =>
                  controller.change(() => controller.isPublicUpdate = value),
              onPickEta: () async {
                final value = await showDatePicker(
                  context: context,
                  initialDate: controller.estimatedCompletionAt ??
                      DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (value != null) {
                  controller
                      .change(() => controller.estimatedCompletionAt = value);
                }
              },
            ),
          ],
          const SizedBox(height: AppDimens.spacingMd),
          OfficerEvidencePicker(
            evidence: controller.evidence,
            onChanged: (files) => controller.change(() {
              controller.evidence
                ..clear()
                ..addAll(files);
            }),
          ),
          const SizedBox(height: AppDimens.spacingLg),
          AppButton(
              label: widget.assignment.status == IncidentStatus.inProgress
                  ? controller.inProgressAction == 'progress'
                      ? 'Đăng cập nhật tiến độ'
                      : 'Gửi kết quả để nghiệm thu'
                  : 'Xác nhận bắt đầu xử lý',
              isLoading: controller.loading,
              onPressed: controller.submit),
        ],
      ),
    );
  }
}
