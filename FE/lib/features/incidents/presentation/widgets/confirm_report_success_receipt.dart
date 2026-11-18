import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';

/// Khối hóa đơn tiếp nhận thành công trên màn hình xác nhận phản ánh
class ConfirmReportSuccessReceipt extends StatelessWidget {
  final String? incidentId;

  const ConfirmReportSuccessReceipt({super.key, this.incidentId});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingLg),
      backgroundColor: AppColors.primaryLight,
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: AppDimens.iconSizeLg,
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),
          Text(
            'Tiếp nhận phản ánh thành công',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingXs),
          Text(
            incidentId != null
                ? 'Mã hồ sơ: #$incidentId'
                : 'Hồ sơ đã được chuyển đến cơ quan xử lý địa bàn.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimens.spacingSm),
          Text(
            'Bạn có thể theo dõi tiến độ xử lý và phản hồi của cán bộ tại mục Lịch sử.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
