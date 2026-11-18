import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/create_report_controller.dart';
import 'review_media_gallery.dart';

/// Thẻ tóm tắt thông tin do người dân cung cấp (Ảnh, Mô tả, Vị trí, Phân loại ban đầu)
class ReviewDetailsCard extends ConsumerWidget {
  final Map<String, dynamic>? data;

  const ReviewDetailsCard({super.key, this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createReportProvider);

    // Dữ liệu từ incident (khi xem lại kết quả đã gửi) hoặc từ state form
    final incidentData = data?['incident'] ?? data;
    final mediaList = incidentData?['media'] as List?;
    final networkImageUrls = (mediaList ?? const [])
        .map((media) => media is Map ? media['file_url']?.toString() : null)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList(growable: false);

    final mediaCount =
        state.media.isNotEmpty ? state.media.length : networkImageUrls.length;

    // Mô tả người dân
    final String description = data != null
        ? (incidentData?['description']?.toString() ?? '')
        : state.description;

    // Vị trí
    final receiptLocation = data?['location'];
    final reportData = data?['report'];
    final responseAddress = receiptLocation?['address']?.toString() ??
        reportData?['reported_address']?.toString() ??
        incidentData?['address']?.toString();
    final coordinates = receiptLocation?['latitude'] != null &&
            receiptLocation?['longitude'] != null
        ? '${receiptLocation['latitude']}, ${receiptLocation['longitude']}'
        : state.location != null
            ? '${state.location!.latitude.toStringAsFixed(5)}, ${state.location!.longitude.toStringAsFixed(5)}'
            : null;
    final String address = responseAddress?.trim().isNotEmpty == true
        ? responseAddress!.trim()
        : state.address?.trim().isNotEmpty == true
            ? state.address!.trim()
            : coordinates ?? 'Chưa xác định địa chỉ';

    // Loại sự cố đã chọn từ trước (nếu có)
    String selectedTypeName = 'Chưa chọn (để AI tự động nhận diện)';
    if (state.incidentTypeId != null) {
      for (final type in state.incidentTypes) {
        if (type['id']?.toString() == state.incidentTypeId) {
          selectedTypeName = type['name']?.toString() ?? selectedTypeName;
          break;
        }
      }
    } else if (incidentData?['incident_type']?['name'] != null) {
      selectedTypeName = incidentData['incident_type']['name'].toString();
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dải ảnh hiện trường có gắn badge số lượng
          Stack(
            children: [
              ReviewMediaGallery(
                files: state.media,
                networkUrls: networkImageUrls,
              ),
              Positioned(
                bottom: AppDimens.spacingSm,
                left: AppDimens.spacingSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingSm + 2,
                    vertical: AppDimens.spacing2Xs + 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$mediaCount ảnh hiện trường',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Nội dung chi tiết người dân đã nhập
          Padding(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thông tin bạn đã cung cấp',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.spacingSm,
                        vertical: AppDimens.spacing2Xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusFull),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'Bước 1',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.spacingMd),

                // Vị trí
                _buildFieldRow(
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.primary,
                  label: 'Vị trí hiện trường',
                  value: address,
                ),
                const SizedBox(height: AppDimens.spacingMd),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: AppDimens.spacingMd),

                // Mô tả
                _buildFieldRow(
                  icon: Icons.notes_rounded,
                  iconColor: AppColors.textSecondary,
                  label: 'Mô tả sự cố',
                  value: description.trim().isEmpty
                      ? 'Không có mô tả chi tiết'
                      : description,
                ),
                const SizedBox(height: AppDimens.spacingMd),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: AppDimens.spacingMd),

                // Phân loại ban đầu
                _buildFieldRow(
                  icon: Icons.category_outlined,
                  iconColor: AppColors.textSecondary,
                  label: 'Phân loại ban đầu',
                  value: selectedTypeName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimens.spacingXs),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimens.radiusXs),
          ),
          child: Icon(icon, size: AppDimens.iconSizeSm, color: iconColor),
        ),
        const SizedBox(width: AppDimens.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
