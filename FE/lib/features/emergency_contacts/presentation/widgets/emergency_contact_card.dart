import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_contact_model.dart';

class EmergencyContactCard extends StatelessWidget {
  const EmergencyContactCard({
    super.key,
    required this.contact,
    required this.isPinned,
    required this.onStarToggle,
    required this.onCall,
    this.isPinnedVariant = false,
    this.inGroup = false,
  });

  final EmergencyContactModel contact;
  final bool isPinned;
  final VoidCallback onStarToggle;
  final VoidCallback onCall;
  final bool isPinnedVariant;
  final bool inGroup;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.spacingMd,
        vertical: inGroup ? AppDimens.spacingSm + 4 : AppDimens.spacingMd - 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  contact.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact.phoneNumber,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isPinnedVariant
                        ? AppColors.emergencyHotlineBg
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.spacingSm),
          IconButton(
            onPressed: onStarToggle,
            iconSize: 22,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isPinned ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isPinned
                  ? AppColors.starGold
                  : AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onCall,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isPinnedVariant
                    ? AppColors.emergencySuccessBorder
                    : AppColors.emergencyHotlineBg,
                shape: BoxShape.circle,
                boxShadow: isPinnedVariant
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.emergencyHotlineBg.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                Icons.call,
                size: 18,
                color: isPinnedVariant
                    ? AppColors.emergencySuccessText
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (inGroup) {
      return content;
    }

    return Container(
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
      child: content,
    );
  }
}
