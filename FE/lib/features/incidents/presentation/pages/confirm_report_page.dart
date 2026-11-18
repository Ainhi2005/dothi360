import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/create_report_controller.dart';
import '../widgets/ai_analysis_card.dart';
import '../widgets/confirm_report_bottom_bar.dart';
import '../widgets/confirm_report_success_receipt.dart';
import '../widgets/report_success_actions.dart';
import '../widgets/review_details_card.dart';
import '../widgets/stepper_widget.dart';

/// Màn hình Xác nhận kết quả AI và Gửi phản ánh của người dân
class ConfirmReportPage extends ConsumerWidget {
  const ConfirmReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createReportProvider);
    final controller = ref.read(createReportProvider.notifier);
    final incident = state.responseData?['incident'] ?? state.responseData;
    final incidentId = incident?['id']?.toString();

    // Lắng nghe lỗi nghiệp vụ nếu có
    ref.listen<CreateReportState>(createReportProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          state.isSuccess ? 'Gửi phản ánh thành công' : 'Xác nhận phản ánh',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: !state.isSuccess,
        actions: state.isSuccess
            ? [
                TextButton(
                  onPressed: () => context.go(AppRoutes.history),
                  child: Text(
                    'Lịch sử',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stepper tiến trình (Bước 2: AI kiểm tra / Bước 3: Hoàn tất)
                    StepperWidget(currentStep: state.isSuccess ? 3 : 2),
                    const SizedBox(height: AppDimens.spacingSm),

                    if (state.isSuccess) ...[
                      // Khối hóa đơn tiếp nhận thành công
                      ConfirmReportSuccessReceipt(incidentId: incidentId),
                      const SizedBox(height: AppDimens.spacingMd),
                      ReviewDetailsCard(data: state.responseData),
                    ] else ...[
                      // Tiêu đề & Hướng dẫn
                      Text(
                        'Kiểm tra & Xác nhận',
                        style: AppTextStyles.headingSmall,
                      ),
                      const SizedBox(height: AppDimens.spacingXs),
                      Text(
                        'Xem lại ảnh, vị trí và xác nhận gợi ý từ AI trước khi gửi đi.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.spacingMd),

                      // 1. Ảnh, loại sự cố, mô tả và vị trí người dân đã cung cấp
                      ReviewDetailsCard(data: state.responseData),
                      const SizedBox(height: AppDimens.spacingMd),

                      // 2, 3, 4. Tóm tắt AI + Gợi ý AI + Trường người dân xác nhận
                      AiAnalysisCard(
                        analysis: state.aiAnalysis,
                        incidentTypes: state.incidentTypes,
                        selectedTypeId: state.incidentTypeId,
                        onTypeChanged: controller.selectIncidentType,
                        onSeverityChanged: controller.selectSeverity,
                        onReasonChanged: controller.updateAnalysisReason,
                        onRecommendationChanged:
                            controller.updateAnalysisRecommendation,
                        isConfirmed: state.isAiConfirmed,
                        onConfirm: controller.confirmAiReview,
                        isRetrying: state.isAnalyzing,
                        onRetry: () => controller.analyzeForReview(),
                      ),
                    ],
                    const SizedBox(height: AppDimens.spacingLg),
                  ],
                ),
              ),
            ),

            // 5. Một CTA gửi phản ánh duy nhất (hoặc Actions khi đã gửi thành công)
            if (state.isSuccess)
              ReportSuccessActions(
                canViewDetail: incidentId != null,
                onCreateAnother: () {
                  controller.reset();
                  context.go(AppRoutes.createReport);
                },
                onViewDetail: () => context.go(
                  incidentId == null
                      ? AppRoutes.history
                      : AppRoutes.incidentDetailPath(incidentId),
                ),
              )
            else
              ConfirmReportBottomBar(
                isLoading: state.isLoading,
                onSubmit: () async {
                  controller.confirmAiReview();
                  if (state.incidentTypeId != null &&
                      state.aiAnalysis?['confirmed_severity'] != null) {
                    await controller.submitReport();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
