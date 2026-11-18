import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

class MediaGridTile extends StatelessWidget {
  const MediaGridTile({super.key, this.file, required this.onTap});
  final File? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.divider)),
          child: const Icon(Icons.add_photo_alternate_outlined,
              color: AppColors.primary),
        ),
      );
    }
    return Stack(fit: StackFit.expand, children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Image.file(file!, fit: BoxFit.cover)),
      Positioned(
          top: AppDimens.spacingXs,
          right: AppDimens.spacingXs,
          child: InkWell(
              onTap: onTap,
              child: CircleAvatar(
                  radius: AppDimens.iconSizeSm,
                  backgroundColor: AppColors.surface,
                  child: Icon(Icons.close,
                      size: AppDimens.iconSizeSm, color: AppColors.error)))),
    ]);
  }
}
