import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../controllers/create_report_controller.dart';
import 'ai_analysis_progress.dart';

/// Thanh hành động dưới màn hình Tạo phản ánh
class CreateReportBottomBar extends ConsumerWidget {
  const CreateReportBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createReportProvider);
    final controller = ref.read(createReportProvider.notifier);
    final isAnalysisFailed = state.analysisStage == 'failed';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingMd,
        vertical: AppDimens.spacingSm + 4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tiến trình đang phân tích
            if (state.isAnalyzing)
              AiAnalysisProgress(
                stage: state.analysisStage,
                uploadProgress: state.uploadProgress,
              ),

            // Trạng thái AI lỗi / Ngoại tuyến -> Cho phép tiếp tục thủ công
            if (isAnalysisFailed) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppDimens.spacingSm),
                padding: const EdgeInsets.all(AppDimens.spacingSm + 2),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: AppDimens.iconSizeSm,
                    ),
                    const SizedBox(width: AppDimens.spacingSm),
                    Expanded(
                      child: Text(
                        'Không thể kết nối phân tích AI. Bạn có thể thử lại hoặc tiếp tục bằng thông tin tự khai báo.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              final ready = await controller.analyzeForReview();
                              if (ready && context.mounted) {
                                context.push(AppRoutes.confirmReport);
                              }
                            },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Thử lại AI'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimens.spacingSm + 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusSm),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.spacingSm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        controller.proceedWithManualFallback();
                        context.push(AppRoutes.confirmReport);
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Tiếp tục thủ công'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimens.spacingSm + 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusSm),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Ghi chú bảo mật gọn gàng
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.spacingSm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dữ liệu bảo mật · Chỉ gửi sau khi bạn xác nhận',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: state.isAnalyzing
                    ? 'AI đang phân tích...'
                    : 'Tiếp tục: AI kiểm tra',
                icon: state.isAnalyzing ? null : Icons.arrow_forward_rounded,
                isLoading: state.isLoading,
                onPressed: () async {
                  final ready = await controller.analyzeForReview();
                  if (ready && context.mounted) {
                    context.push(AppRoutes.confirmReport);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
