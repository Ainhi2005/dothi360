import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_contact_model.dart';
import 'emergency_contact_card.dart';

class EmergencyContactGroup extends StatelessWidget {
  const EmergencyContactGroup({
    super.key,
    required this.title,
    this.titleIcon,
    required this.contacts,
    required this.pinnedPhoneNumbers,
    required this.onStarToggle,
    required this.onCall,
    this.isPinnedSection = false,
  });

  final String title;
  final Widget? titleIcon;
  final List<EmergencyContactModel> contacts;
  final Set<String> pinnedPhoneNumbers;
  final ValueChanged<String> onStarToggle;
  final ValueChanged<EmergencyContactModel> onCall;
  final bool isPinnedSection;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (titleIcon != null) ...[
              titleIcon!,
              const SizedBox(width: 5),
            ],
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.spacingSm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd + 4),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < contacts.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider.withValues(alpha: 0.7),
                  ),
                EmergencyContactCard(
                  contact: contacts[i],
                  isPinned: pinnedPhoneNumbers.contains(contacts[i].phoneNumber),
                  isPinnedVariant: isPinnedSection,
                  inGroup: true,
                  onStarToggle: () => onStarToggle(contacts[i].phoneNumber),
                  onCall: () => onCall(contacts[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
