import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../incidents/presentation/widgets/incident_status_chip.dart';

/// Thẻ xem trước sự cố khi chạm vào marker trên bản đồ
class MapIncidentPreviewCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  final String? distanceText;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const MapIncidentPreviewCard({
    super.key,
    required this.incident,
    this.distanceText,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final typeName =
        incident['incident_type']?['name']?.toString() ?? 'Sự cố đô thị';
    final desc = incident['description']?.toString() ?? '';
    final status = incident['status']?.toString() ?? 'PENDING_ASSIGNMENT';
    final reportCount = incident['report_count'] ?? 1;

    // Trích xuất URL ảnh nếu có
    String? imageUrl;
    final mediaList = incident['media'] as List?;
    if (mediaList != null && mediaList.isNotEmpty) {
      final firstMedia = mediaList.first;
      imageUrl = firstMedia is Map
          ? firstMedia['file_url']?.toString()
          : firstMedia?.toString();
    } else if (incident['file_url'] != null) {
      imageUrl = incident['file_url'].toString();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingSm + 4,
        vertical: AppDimens.spacingSm,
      ),
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng trên: Ảnh thumbnail (nếu có) + Thông tin tóm tắt
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: AppCachedImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      errorWidget: _buildPlaceholder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.spacingSm + 2),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hàng trạng thái + khoảng cách + nút đóng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IncidentStatusChip(status: status),
                              if (distanceText != null &&
                                  distanceText!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(
                                        AppDimens.radiusXs),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.near_me_outlined,
                                        size: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        distanceText!,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: onClose,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusFull),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.spacingXs),

                    // Loại sự cố
                    Text(
                      typeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Mô tả ngắn
                    if (desc.trim().isNotEmpty)
                      Text(
                        desc.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSm + 4),

          // Hàng dưới: Số lượng xác nhận & Nút xem chi tiết
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.group_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$reportCount người cùng báo',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('Xem chi tiết'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingMd,
                    vertical: AppDimens.spacingXs,
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

  Widget _buildPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.background,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.textDisabled,
          size: 24,
        ),
      ),
    );
  }
}
