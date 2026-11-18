import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/create_report_controller.dart';
import '../../data/models/incident_location_selection.dart';

/// Thẻ định vị GPS hiện trường sự cố
class LocationCard extends ConsumerWidget {
  const LocationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createReportProvider);
    final controller = ref.read(createReportProvider.notifier);
    final hasLocation = state.location != null;

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Trạng thái định vị
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: AppDimens.iconSizeBase,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimens.spacingSm),
                  Text(
                    'Vị trí sự cố',
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
                  horizontal: AppDimens.spacingSm,
                  vertical: AppDimens.spacing2Xs,
                ),
                decoration: BoxDecoration(
                  color: hasLocation
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  border: Border.all(
                    color: hasLocation
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasLocation
                          ? Icons.check_circle_outline_rounded
                          : Icons.location_searching_rounded,
                      size: 12,
                      color:
                          hasLocation ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasLocation ? 'Đã chọn' : 'Chưa có vị trí',
                      style: AppTextStyles.caption.copyWith(
                        color:
                            hasLocation ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingXs),
          Text(
            'Chọn đúng nơi xảy ra sự cố, kể cả khi bạn đang báo cáo từ một vị trí khác.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),

          // Khối hiển thị thông tin địa chỉ & Tọa độ
          Container(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimens.spacingSm),
                  decoration: BoxDecoration(
                    color: hasLocation
                        ? AppColors.primaryLight
                        : AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasLocation
                        ? Icons.my_location_rounded
                        : Icons.location_disabled_rounded,
                    color: hasLocation
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: AppDimens.iconSizeSm,
                  ),
                ),
                const SizedBox(width: AppDimens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.address ??
                            (hasLocation
                                ? 'Đã chọn vị trí sự cố'
                                : 'Chưa xác định được vị trí'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.spacing2Xs),
                      Text(
                        hasLocation
                            ? 'Tọa độ: ${state.location!.latitude.toStringAsFixed(6)}, ${state.location!.longitude.toStringAsFixed(6)}'
                            : 'Tìm địa chỉ, chạm trên bản đồ hoặc dùng GPS',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spacingSm),

          // Nút cập nhật vị trí
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      state.isLoading ? null : controller.getCurrentLocation,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 16),
                  label: Text(
                    'GPS hiện tại',
                    style: AppTextStyles.buttonText.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spacingSm,
                      vertical: AppDimens.spacingXs,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.spacingSm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          final result =
                              await context.push<IncidentLocationSelection>(
                            AppRoutes.reportLocation,
                            extra: state.location == null
                                ? null
                                : IncidentLocationSelection(
                                    point: state.location!,
                                    address: state.address,
                                    source: state.locationSource,
                                  ),
                          );
                          if (!context.mounted) return;
                          if (result != null) {
                            controller.setIncidentLocation(
                              location: result.point,
                              address: result.address,
                              source: result.source,
                            );
                          }
                        },
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: Text(
                    hasLocation ? 'Chỉnh trên bản đồ' : 'Chọn trên bản đồ',
                    style: AppTextStyles.buttonText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
