import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_cached_image.dart';

/// Bộ sưu tập hiển thị ảnh hiện trường thu nhỏ trên màn hình duyệt/xác nhận
class ReviewMediaGallery extends StatelessWidget {
  const ReviewMediaGallery({
    super.key,
    this.files = const [],
    this.networkUrls = const [],
  });

  final List<File> files;
  final List<String> networkUrls;

  int get _itemCount => files.isNotEmpty ? files.length : networkUrls.length;

  @override
  Widget build(BuildContext context) {
    final count = _itemCount;
    if (count == 0) return _buildEmpty();

    return SizedBox(
      height: 180,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimens.radiusMd),
          topRight: Radius.circular(AppDimens.radiusMd),
        ),
        child: count == 1 ? _buildImageTile(0) : _buildMultiple(count),
      ),
    );
  }

  Widget _buildMultiple(int count) {
    if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildImageTile(0)),
          const SizedBox(width: AppDimens.spacing2Xs),
          Expanded(child: _buildImageTile(1)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 2, child: _buildImageTile(0)),
        const SizedBox(width: AppDimens.spacing2Xs),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildImageTile(1)),
              const SizedBox(height: AppDimens.spacing2Xs),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImageTile(2),
                    if (count > 3)
                      ColoredBox(
                        color: Colors.black.withValues(alpha: 0.6),
                        child: Center(
                          child: Text(
                            '+${count - 3}',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(int index) {
    if (files.isNotEmpty) {
      return Image.file(
        files[index],
        cacheWidth: AppDimens.mediaPreviewDecodeWidth,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildBroken(),
      );
    }
    return AppCachedImage(
      imageUrl: networkUrls[index],
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: 300,
    );
  }

  Widget _buildEmpty() => Container(
        width: double.infinity,
        height: 140,
        color: AppColors.background,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textSecondary,
            size: AppDimens.iconSizeLg,
          ),
        ),
      );

  Widget _buildBroken() => ColoredBox(
        color: AppColors.background,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.textSecondary,
            size: AppDimens.iconSizeMd,
          ),
        ),
      );
}
