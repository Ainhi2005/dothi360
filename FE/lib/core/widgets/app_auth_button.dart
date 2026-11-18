import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

class AppAuthButton extends StatelessWidget {
  const AppAuthButton(
      {required this.label,
      required this.onPressed,
      this.isLoading = false,
      this.outlined = false,
      this.icon,
      super.key});
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
        height: AppDimens.authControlHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.authButtonRadius),
          gradient: outlined
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.authGreen, AppColors.primary]),
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: .16),
                      blurRadius: AppDimens.spacingBase,
                      offset: const Offset(0, AppDimens.spacingXs))
                ],
        ),
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: outlined ? AppColors.authInk : AppColors.surface,
            side: BorderSide(
                color: outlined ? AppColors.primary : Colors.transparent),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimens.authButtonRadius)),
            textStyle: Theme.of(context)
                .textTheme
                .labelLarge
                ?.merge(AppTextStyles.authButton),
          ),
          child: isLoading
              ? const SizedBox(
                  width: AppDimens.iconSizeMd,
                  height: AppDimens.iconSizeMd,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.surface))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (outlined && icon != null) ...[
                    Icon(icon, size: AppDimens.iconSizeMd),
                    const SizedBox(width: AppDimens.spacingSm)
                  ],
                  Flexible(child: Text(label, textAlign: TextAlign.center)),
                  if (!outlined && icon != null) ...[
                    const SizedBox(width: AppDimens.spacingBase),
                    Icon(icon, size: AppDimens.iconSizeMd)
                  ],
                ]),
        ),
      );
}
