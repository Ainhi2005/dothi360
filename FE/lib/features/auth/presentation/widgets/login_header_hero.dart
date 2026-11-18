import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class LoginHeaderHero extends StatelessWidget {
  const LoginHeaderHero({super.key});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset(AppAssets.authLoginBackground,
            fit: BoxFit.cover, alignment: Alignment.center),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.surface, Colors.transparent],
                    stops: [0, .65]))),
        SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingLg,
                  vertical: AppDimens.spacingXl),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Image.asset(AppAssets.mainLogo,
                      width: AppDimens.authLogoSize,
                      height: AppDimens.authLogoSize),
                  const SizedBox(width: AppDimens.spacingSm),
                  const Flexible(
                      child:
                          Text('ĐÔ THỊ 360', style: AppTextStyles.authBrand)),
                ]),
                const SizedBox(height: AppDimens.spacingSm),
                const Text(
                    'Phản ánh sự cố, theo dõi xử lý,\ncùng giữ gìn đô thị của bạn.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authBody),
              ]),
            )),
      ]);
}
