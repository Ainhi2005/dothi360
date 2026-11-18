import 'package:flutter/material.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_cached_image.dart';

class IncidentMediaGallery extends StatelessWidget {
  final List<String> imageUrls;
  final String title;
  const IncidentMediaGallery({
    super.key,
    required this.imageUrls,
    this.title = 'Ảnh hiện trường',
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.titleMedium),
      const SizedBox(height: AppDimens.spacingSm),
      SizedBox(
        height: 190,
        child: PageView.builder(
          itemCount: imageUrls.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(
                right: index == imageUrls.length - 1 ? 0 : AppDimens.spacingSm),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              child: AppCachedImage(
                imageUrl: imageUrls[index],
                fit: BoxFit.cover,
                memCacheWidth: 600,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
