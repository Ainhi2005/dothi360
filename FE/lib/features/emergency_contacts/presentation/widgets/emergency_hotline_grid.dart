import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_contact_model.dart';
import 'emergency_call_dialog.dart';

class EmergencyHotlineGrid extends StatelessWidget {
  const EmergencyHotlineGrid({super.key, required this.hotlines});

  final List<EmergencyContactModel> hotlines;

  @override
  Widget build(BuildContext context) {
    if (hotlines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emergency, color: AppColors.error, size: AppDimens.iconSizeSm),
            const SizedBox(width: AppDimens.spacingXs),
            Text(
              'Đường dây nóng cấp thiết',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingSm, vertical: AppDimens.spacingXs),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Text(
                'GỌI 24/7',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.spacingSm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppDimens.spacingSm,
            mainAxisSpacing: AppDimens.spacingSm,
            childAspectRatio: 1.45,
          ),
          itemCount: hotlines.length,
          itemBuilder: (context, index) {
            final item = hotlines[index];
            return _HotlineTile(contact: item);
          },
        ),
      ],
    );
  }
}

class _HotlineTile extends StatelessWidget {
  const _HotlineTile({required this.contact});

  final EmergencyContactModel contact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => EmergencyCallDialog.show(context, contact),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.spacingSm),
          decoration: BoxDecoration(
            color: contact.accentBgColor,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: contact.accentColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimens.spacingXs),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                    child: Icon(contact.iconData, color: contact.accentColor, size: AppDimens.iconSizeMd),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingSm, vertical: 2),
                    decoration: BoxDecoration(
                      color: contact.accentColor,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, color: Colors.white, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          'Gọi',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.phoneNumber,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: contact.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
