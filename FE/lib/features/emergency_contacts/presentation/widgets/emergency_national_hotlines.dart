import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_contact_model.dart';

class EmergencyNationalHotlines extends StatelessWidget {
  const EmergencyNationalHotlines({
    super.key,
    required this.hotlines,
    required this.onContactTap,
  });

  final List<EmergencyContactModel> hotlines;
  final ValueChanged<EmergencyContactModel> onContactTap;

  Color _getNumberColor(String number) {
    if (number.contains('114')) return AppColors.error;
    if (number.contains('115')) return AppColors.info;
    if (number.contains('113')) return AppColors.warning;
    if (number.contains('111')) return AppColors.emergencyTeal;
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    // Sort or filter the 4 national hotlines: 114, 115, 113, 111
    final ordered = ['114', '115', '113', '111'];
    final items = <EmergencyContactModel>[];
    for (final num in ordered) {
      final found = hotlines.cast<EmergencyContactModel?>().firstWhere(
            (c) => c!.phoneNumber.trim() == num,
            orElse: () => null,
          );
      if (found != null) {
        items.add(found);
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'QUỐC GIA (ƯU TIÊN SỐ 1)',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingSm + 2,
                vertical: AppDimens.spacingXs - 1,
              ),
              decoration: BoxDecoration(
                color: AppColors.emergencySuccessBorder.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              ),
              child: Text(
                '24/7 Miễn cước',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.emergencySuccessText,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.spacingSm),
        Row(
          children: items.map((contact) {
            final color = _getNumberColor(contact.phoneNumber);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd + 4),
                  child: InkWell(
                    onTap: () => onContactTap(contact),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd + 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.spacingMd - 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd + 4),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            contact.phoneNumber,
                            style: AppTextStyles.headingSmall.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: color,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contact.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
