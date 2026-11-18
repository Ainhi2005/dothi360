import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Khối hiển thị tiến trình xử lý AI và tải ảnh
class AiAnalysisProgress extends StatelessWidget {
  const AiAnalysisProgress({
    super.key,
    required this.stage,
    required this.uploadProgress,
  });

  final String stage;
  final double uploadProgress;

  @override
  Widget build(BuildContext context) {
    final analyzing = stage == 'analyzing';
    final title =
        analyzing ? 'AI đang phân tích hiện trường...' : 'Đang tải tệp an toàn';
    final detail = analyzing
        ? 'Nhận diện phân loại, ước tính mức độ rủi ro và đơn vị tiếp nhận.'
        : 'Đã tải ${(uploadProgress * 100).round()}% · Vui lòng giữ ứng dụng mở.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimens.spacingMd),
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: AppDimens.iconSizeBase,
            height: AppDimens.iconSizeBase,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: AppDimens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppDimens.spacing2Xs),
                Text(
                  detail,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
