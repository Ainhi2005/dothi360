import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_contact_model.dart';

class EmergencyCallSheet extends StatelessWidget {
  const EmergencyCallSheet({
    super.key,
    required this.contact,
  });

  final EmergencyContactModel contact;

  static Future<void> show(
    BuildContext context,
    EmergencyContactModel contact,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EmergencyCallSheet(contact: contact),
    );
  }

  Future<void> _makeCall(BuildContext context) async {
    final clean = contact.phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    Navigator.of(context).pop();
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể mở cuộc gọi đến $clean'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Số liên hệ khẩn cấp: $clean'),
          ),
        );
      }
    }
  }

  void _copyNumber(BuildContext context) {
    Clipboard.setData(ClipboardData(text: contact.phoneNumber));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép số ${contact.phoneNumber}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLg + 4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.spacingLg,
        AppDimens.spacingSm,
        AppDimens.spacingLg,
        AppDimens.spacingXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
          ),
          const SizedBox(height: AppDimens.spacingLg),
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.categoryFireBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_in_talk_outlined,
              color: AppColors.categoryFire,
              size: 28,
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),
          Text(
            contact.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingXs),
          Text(
            contact.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),
          Text(
            contact.phoneNumber,
            style: AppTextStyles.headingLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppDimens.spacingLg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _makeCall(context),
              icon: const Icon(Icons.call, color: Colors.white, size: 20),
              label: const Text(
                'GỌI NGAY LẬP TỨC',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyHotlineBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd + 4),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.spacingSm + 2),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () => _copyNumber(context),
                    icon: const Icon(
                      Icons.content_copy_outlined,
                      size: 17,
                      color: AppColors.textPrimary,
                    ),
                    label: const Text(
                      'Sao chép số',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd + 2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.spacingSm + 2),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.searchBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd + 2),
                      ),
                    ),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
