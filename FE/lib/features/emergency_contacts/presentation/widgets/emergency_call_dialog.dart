import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_contact_model.dart';

class EmergencyCallDialog extends StatelessWidget {
  const EmergencyCallDialog({super.key, required this.contact});

  final EmergencyContactModel contact;

  static Future<void> show(BuildContext context, EmergencyContactModel contact) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => EmergencyCallDialog(contact: contact),
    );
  }

  Future<void> _makeCall(BuildContext context) async {
    final uri = Uri.parse('tel:${contact.phoneNumber.replaceAll(RegExp(r'\s+'), '')}');
    Navigator.of(context).pop();
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở trình gọi điện cho số ${contact.phoneNumber}'),
            backgroundColor: AppColors.error,
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
        content: Text('Đã sao chép số ${contact.phoneNumber} vào bộ nhớ tạm'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: contact.accentBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(contact.iconData, color: contact.accentColor, size: AppDimens.iconSizeLg),
            ),
            const SizedBox(height: AppDimens.spacingMd),
            Text(
              'Gọi số khẩn cấp',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.spacingXs),
            Text(
              contact.name,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMd, vertical: AppDimens.spacingSm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                contact.phoneNumber,
                style: AppTextStyles.headingMedium.copyWith(color: contact.accentColor),
              ),
            ),
            const SizedBox(height: AppDimens.spacingMd),
            Text(
              'Vui lòng chỉ gọi số này khi có tình huống thực sự cần hỗ trợ khẩn cấp.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.spacingLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _copyNumber(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppDimens.spacingSm),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                    ),
                    child: const Text('Sao chép số'),
                  ),
                ),
                const SizedBox(width: AppDimens.spacingSm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _makeCall(context),
                    icon: const Icon(Icons.phone),
                    label: const Text('Gọi ngay'),
                    style: FilledButton.styleFrom(
                      backgroundColor: contact.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: AppDimens.spacingSm),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
