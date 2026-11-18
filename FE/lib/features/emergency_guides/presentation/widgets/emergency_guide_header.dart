import 'package:flutter/material.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_back_button.dart';

class EmergencyGuideHeader extends StatelessWidget {
  const EmergencyGuideHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.spacingXs,
        AppDimens.spacingXs,
        AppDimens.spacingMd,
        AppDimens.spacingSm,
      ),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: AppDimens.spacingXs),
          Expanded(
            child: Text(
              'Cẩm nang khẩn cấp',
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
