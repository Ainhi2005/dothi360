import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

class AppAuthTextField extends StatefulWidget {
  const AppAuthTextField(
      {required this.hint,
      required this.icon,
      required this.controller,
      this.isPassword = false,
      this.keyboardType,
      this.textInputAction = TextInputAction.next,
      this.onSubmitted,
      this.autofillHints,
      this.enabled = true,
      super.key});
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  @override
  State<AppAuthTextField> createState() => _AppAuthTextFieldState();
}

class _AppAuthTextFieldState extends State<AppAuthTextField> {
  bool _visible = false;
  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        enabled: widget.enabled,
        obscureText: widget.isPassword && !_visible,
        enableSuggestions: !widget.isPassword,
        autocorrect: !widget.isPassword,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        autofillHints: widget.autofillHints,
        style: AppTextStyles.authField,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle:
              AppTextStyles.authField.copyWith(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.authCanvas,
          contentPadding: const EdgeInsets.symmetric(
              vertical: AppDimens.spacingMd, horizontal: AppDimens.spacingMd),
          prefixIcon: Icon(widget.icon,
              color: AppColors.primaryDark, size: AppDimens.iconSizeBase),
          suffixIcon: widget.isPassword
              ? IconButton(
                  tooltip: _visible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                  onPressed: () => setState(() => _visible = !_visible),
                  icon: Icon(
                      _visible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: AppDimens.iconSizeBase),
                )
              : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              borderSide: const BorderSide(color: AppColors.authBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              borderSide: const BorderSide(color: AppColors.authBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              borderSide: const BorderSide(color: AppColors.authGreen)),
        ),
      );
}
