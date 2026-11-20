import 'package:flutter/material.dart';
import '../../../../core/theme/app_dimens.dart';
import 'dart:io';

class OfficerEvidenceThumbnail extends StatelessWidget {
  const OfficerEvidenceThumbnail(
      {required this.file, required this.onRemove, super.key});
  final File file;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            child: Image.file(
              file,
              cacheWidth: AppDimens.mediaThumbnailDecodeWidth,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton.filled(
              onPressed: () => onRemove(),
              icon: const Icon(Icons.close, size: AppDimens.iconSizeSm),
            ),
          ),
        ],
      );
}
