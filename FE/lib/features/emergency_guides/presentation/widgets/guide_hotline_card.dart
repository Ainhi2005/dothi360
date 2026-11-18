import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_guide_model.dart';

class GuideHotlineCard extends StatelessWidget {
  const GuideHotlineCard({
    super.key,
    required this.guide,
  });

  final EmergencyGuideModel guide;

  Future<void> _makeCall(BuildContext context, String number) async {
    final cleanNumber = number.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể gọi đến số $cleanNumber')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Số tổng đài cứu hộ: $cleanNumber')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = guide.phoneNumbers.isNotEmpty
        ? guide.phoneNumbers.first
        : const EmergencyPhoneModel(label: 'Cứu hỏa và cứu nạn', number: '114');

    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(
          color: AppColors.emergencyAlertBorder.withValues(alpha: 0.9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.categoryFire.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: AppDimens.emergencyIconBoxSize,
            height: AppDimens.emergencyIconBoxSize,
            decoration: BoxDecoration(
              color: AppColors.categoryMedicalBg,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd + 2),
            ),
            child: const Icon(
              Icons.phone_in_talk_rounded,
              color: AppColors.categoryFire,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimens.spacingMd - 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TỔNG ĐÀI CỨU HỘ',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  phone.number,
                  style: AppTextStyles.headingSmall.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emergencyPillBg,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.spacingSm),
          InkWell(
            onTap: () => _makeCall(context, phone.number),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd + 4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingMd,
                vertical: AppDimens.spacingSm + 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.emergencyHotlineBg,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd + 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emergencyHotlineBg.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.call,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GỌI\nNGAY',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      height: 1.1,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
