import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class RegisterHeaderHero extends StatelessWidget {
  const RegisterHeaderHero({required this.onBack, super.key});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset(AppAssets.authRegisterBackground,
            fit: BoxFit.cover, alignment: const Alignment(0, -.65)),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.authWaveLight, Colors.transparent],
                    stops: [0, .55]))),
        SafeArea(
            bottom: false,
            child: Align(
                alignment: Alignment.topCenter,
                child: Row(children: [
                  IconButton(
                      onPressed: onBack,
                      tooltip: 'Quay lại',
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.authInk)),
                  const Expanded(
                      child: Text('Đăng ký tài khoản',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.authLink)),
                  const SizedBox(width: AppDimens.minTouchTarget),
                ]))),
      ]);
}
