import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class AccountSettingTile extends StatelessWidget {
  const AccountSettingTile({
    super.key,
    required this.title,
    this.assetPath,
    this.icon,
    this.subtitle,
    this.trailingText,
    this.onTap,
    this.trailing,
  }) : assert(assetPath != null || icon != null);

  final String? assetPath;
  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacingBase,
          vertical: AppDimens.spacingXs,
        ),
        minLeadingWidth: AppDimens.accountMenuIconSize,
        leading: SizedBox(
          width: AppDimens.accountMenuIconSize,
          height: AppDimens.accountMenuIconSize,
          child: assetPath != null
              ? Image.asset(
                  assetPath!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported_outlined,
                    size: AppDimens.iconSizeMd,
                    color: AppColors.textSecondary,
                  ),
                )
              : Icon(
                  icon ?? Icons.circle_outlined,
                  size: AppDimens.iconSizeMd,
                  color: AppColors.primary,
                ),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall,
              ),
        trailing: trailing ??
            (onTap == null && trailingText == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trailingText != null)
                        Text(trailingText!, style: AppTextStyles.bodySmall),
                      if (trailingText != null)
                        const SizedBox(width: AppDimens.spacingXs),
                      const Icon(
                        Icons.chevron_right,
                        size: AppDimens.iconSizeBase,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  )),
        onTap: onTap,
      );
}
