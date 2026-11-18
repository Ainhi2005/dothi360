import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/create_report_controller.dart';

/// Thẻ chọn và quản lý ảnh/video hiện trường
class ImagePickerCard extends ConsumerWidget {
  const ImagePickerCard({super.key});

  static const int _maxMediaCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createReportProvider);
    final controller = ref.read(createReportProvider.notifier);
    final mediaCount = state.media.length;
    final canAddMore = mediaCount < _maxMediaCount;

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Chỉ số số lượng ảnh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.photo_camera_rounded,
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
                  const SizedBox(width: AppDimens.spacingXs),
                  Text(
                    '*',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingSm + 2,
                  vertical: AppDimens.spacing2Xs + 1,
                ),
                decoration: BoxDecoration(
                  color: mediaCount > 0
                      ? AppColors.primaryLight
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  border: Border.all(
                    color: mediaCount > 0
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  '$mediaCount/$_maxMediaCount tệp',
                  style: AppTextStyles.caption.copyWith(
                    color: mediaCount > 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingXs),
          Text(
            'Chụp rõ góc rộng và cận cảnh sự cố để AI phân tích chính xác nhất.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),

          // Vùng hiển thị ảnh
          if (state.media.isEmpty)
            _buildEmptyUploadZone(context, controller)
          else
            _buildMediaPreviewArea(
                context, controller, state.media, canAddMore),

          // Trạng thái Upload nếu đang tải
          if (state.analysisStage == 'uploading') ...[
            const SizedBox(height: AppDimens.spacingMd),
            _buildUploadProgress(state.uploadProgress),
          ],
        ],
      ),
    );
  }

  /// Trạng thái chưa có ảnh
  Widget _buildEmptyUploadZone(
    BuildContext context,
    CreateReportController controller,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.spacingLg,
        horizontal: AppDimens.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: AppColors.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.add_a_photo_outlined,
              size: AppDimens.iconSizeLg,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingSm),
          Text(
            'Chưa có ảnh hiện trường',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingXs),
          Text(
            'Hỗ trợ chụp tối đa 5 ảnh hoặc video ngắn',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => controller.pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Chụp ngay'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingMd,
                    vertical: AppDimens.spacingSm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.spacingSm),
              OutlinedButton.icon(
                onPressed: () => controller.pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Từ thư viện'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingMd,
                    vertical: AppDimens.spacingSm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Trạng thái đã có ảnh: Ảnh chính lớn + Thumbnail danh sách
  Widget _buildMediaPreviewArea(
    BuildContext context,
    CreateReportController controller,
    List<File> mediaList,
    bool canAddMore,
  ) {
    final primaryFile = mediaList.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ảnh chính nổi bật
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Stack(
            children: [
              Image.file(
                primaryFile,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: AppDimens.spacingSm,
                left: AppDimens.spacingSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingSm,
                    vertical: AppDimens.spacing2Xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ảnh đại diện',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: AppDimens.spacingSm,
                right: AppDimens.spacingSm,
                child: GestureDetector(
                  onTap: () => controller.removeMediaAt(0),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.spacingXs),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.spacingSm),

        // Thumbnail các ảnh phụ và nút thêm
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: mediaList.length + (canAddMore ? 1 : 0),
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppDimens.spacingSm),
            itemBuilder: (context, index) {
              if (index == mediaList.length) {
                // Ô thêm ảnh
                return _buildAddMoreTile(controller);
              }
              final isCover = index == 0;
              final file = mediaList[index];

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isCover ? AppColors.primary : AppColors.border,
                          width: isCover ? 2.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      ),
                      child: Image.file(
                        file,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => controller.removeMediaAt(index),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddMoreTile(CreateReportController controller) {
    return InkWell(
      onTap: () => controller.pickImage(ImageSource.gallery),
      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(height: 2),
            Text(
              'Thêm',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress(double progress) {
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingSm + 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đang tải tệp an toàn lên máy chủ...',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '$percent%',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingXs),
          LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          ),
        ],
      ),
    );
  }
}
