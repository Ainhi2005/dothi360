import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Widget nạp ảnh có cache bộ nhớ và đĩa, tự động giới hạn kích thước decode
/// giúp triệt tiêu hiện tượng lag/jank khi cuộn danh sách sự cố.
class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.memCacheWidth = 400,
    this.memCacheHeight,
    this.placeholderIcon = Icons.image_outlined,
    this.errorWidget,
    this.placeholder,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final IconData placeholderIcon;
  final Widget? errorWidget;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final validUrl = imageUrl?.trim() ?? '';
    if (validUrl.isEmpty) {
      return _buildPlaceholder();
    }

    Widget image = CachedNetworkImage(
      imageUrl: validUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: AppColors.surfaceSubtle,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      errorWidget: (context, url, error) => errorWidget ?? _buildPlaceholder(),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildPlaceholder() {
    if (errorWidget != null) return errorWidget!;
    Widget box = Container(
      width: width,
      height: height,
      color: AppColors.surfaceSubtle,
      child: Center(
        child: Icon(
          placeholderIcon,
          color: AppColors.textTertiary,
          size: 26,
        ),
      ),
    );
    if (borderRadius != null) {
      box = ClipRRect(borderRadius: borderRadius!, child: box);
    }
    return box;
  }
}
