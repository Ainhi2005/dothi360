import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Dải cảnh báo khẩn cấp (Gọi 114) nếu xảy ra nguy hiểm tính mạng
class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingMd,
        vertical: AppDimens.spacingSm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emergency_rounded,
            color: AppColors.error,
            size: AppDimens.iconSizeMd,
          ),
          const SizedBox(width: AppDimens.spacingSm),
          Expanded(
            child: Text(
              'Có người gặp nguy hiểm? Gọi cứu nạn khẩn cấp:',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.spacingSm),
          FilledButton.icon(
            onPressed: () async {
              await launchUrl(Uri(scheme: 'tel', path: '114'));
            },
            icon: const Icon(
              Icons.phone_in_talk_rounded,
              size: AppDimens.iconSizeSm,
            ),
            label: const Text('114'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingSm + 2,
                vertical: AppDimens.spacingXs,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
