import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_cached_image.dart';

/// Thẻ thư viện ảnh hiện trường Trước / Sau xử lý
class IncidentScenePhotosCard extends StatefulWidget {
  final List<String> reporterImages;
  final List<String> officerImages;

  const IncidentScenePhotosCard({
    super.key,
    required this.reporterImages,
    this.officerImages = const [],
  });

  @override
  State<IncidentScenePhotosCard> createState() =>
      _IncidentScenePhotosCardState();
}

class _IncidentScenePhotosCardState extends State<IncidentScenePhotosCard> {
  int _selectedTab = 0; // 0: Trước xử lý, 1: Sau xử lý

  void _showImageDialog(BuildContext context, String imageUrl, String tag) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppDimens.spacingSm),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: AppCachedImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  memCacheWidth: 1024,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final beforeImages = widget.reporterImages;
    final afterImages = widget.officerImages;
    final hasAfter = afterImages.isNotEmpty;

    final activeList = _selectedTab == 0 ? beforeImages : afterImages;

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: AppDimens.iconSizeBase,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimens.spacingSm),
                  Text(
                    'Ảnh hiện trường',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                'Nhấn để xem lớn',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSm),

          // Bộ chọn Trước / Sau (Before / After selector)
          Container(
            padding: const EdgeInsets.all(3.0),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    label: 'Trước xử lý (${beforeImages.length})',
                    icon: Icons.history_rounded,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    label: hasAfter
                        ? 'Sau khắc phục (${afterImages.length})'
                        : 'Sau khắc phục (Chờ)',
                    icon: Icons.check_circle_outline_rounded,
                    isDisabled: !hasAfter,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),

          // Danh sách ảnh theo tab được chọn
          if (activeList.isEmpty)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: AppDimens.spacingLg),
              alignment: Alignment.center,
              child: Text(
                _selectedTab == 0
                    ? 'Chưa có ảnh hiện trường ban đầu'
                    : 'Đội xử lý đang khắc phục, ảnh sau xử lý sẽ hiển thị tại đây.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: activeList.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppDimens.spacingSm),
                itemBuilder: (context, index) {
                  final url = activeList[index];
                  final tag = _selectedTab == 0
                      ? 'Ảnh gửi ${index + 1}'
                      : 'Kết quả ${index + 1}';

                  return GestureDetector(
                    onTap: () => _showImageDialog(context, url, tag),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      child: Stack(
                        children: [
                          AppCachedImage(
                            imageUrl: url,
                            width: 150,
                            height: 120,
                            fit: BoxFit.cover,
                            memCacheWidth: 300,
                          ),
                          Positioned(
                            left: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusXs),
                              ),
                              child: Text(
                                tag,
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    bool isDisabled = false,
  }) {
    final isSelected = _selectedTab == index;

    return InkWell(
      onTap: isDisabled ? null : () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(AppDimens.radiusXs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppDimens.spacingSm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusXs),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isDisabled
                  ? AppColors.textDisabled
                  : (isSelected ? AppColors.primary : AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isDisabled
                    ? AppColors.textDisabled
                    : (isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
