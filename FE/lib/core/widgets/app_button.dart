import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

enum AppButtonType { primary, secondary, outline, text, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final TextStyle? textStyle;
  final double? iconSize;
  final bool isTrailingIcon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.backgroundColor,
    this.padding,
    this.height,
    this.textStyle,
    this.iconSize,
    this.isTrailingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = SizedBox(
      height: height ?? AppDimens.buttonHeight,
      width: isFullWidth ? double.infinity : null,
      child: _buildButton(),
    );
    return button;
  }

  Widget _buildButton() {
    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primary,
            foregroundColor: Colors.white,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            elevation: 0,
          ),
          child: _buildChild(Colors.white),
        );
      case AppButtonType.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            elevation: 0,
          ),
          child: _buildChild(AppColors.textPrimary),
        );
      case AppButtonType.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
          ),
          child: _buildChild(AppColors.primary),
        );
      case AppButtonType.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.error,
            foregroundColor: Colors.white,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            elevation: 0,
          ),
          child: _buildChild(Colors.white),
        );
      case AppButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: padding,
          ),
          child: _buildChild(AppColors.primary),
        );
    }
  }

  Widget _buildChild(Color contentColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(contentColor),
        ),
      );
    }

    final effectiveStyle =
        (textStyle ?? AppTextStyles.buttonText).copyWith(color: contentColor);

    if (icon != null) {
      final iconWidget = Icon(
        icon,
        color: contentColor,
        size: iconSize ?? AppDimens.iconSizeMd,
      );
      final textWidget = Flexible(
        child: Text(
          label,
          style: effectiveStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );

      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: isTrailingIcon
            ? [
                textWidget,
                const SizedBox(width: AppDimens.spacingSm),
                iconWidget,
              ]
            : [
                iconWidget,
                const SizedBox(width: AppDimens.spacingSm),
                textWidget,
              ],
      );
    }
    return Text(
      label,
      style: effectiveStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
