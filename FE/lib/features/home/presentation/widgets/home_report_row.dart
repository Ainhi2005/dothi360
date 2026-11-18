import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_status_badge.dart';

/// Dòng phản ánh sự cố của người dân trong khối Hồ sơ
class HomeReportRow extends StatelessWidget {
  const HomeReportRow({super.key, required this.report});

  final Map<String, dynamic> report;

  @override
  Widget build(BuildContext context) {
    final incident = Map<String, dynamic>.from(report['incident'] ?? const {});
    final media = List<Map<String, dynamic>>.from(report['media'] ?? const []);
    final image = media.isEmpty ? null : media.first['file_url']?.toString();
    final status = incident['status']?.toString() ?? 'PENDING_ASSIGNMENT';
    final incidentId = incident['id']?.toString() ?? '';

    return InkWell(
      onTap: () {
        if (incidentId.isNotEmpty) {
          context.push(AppRoutes.incidentDetailPath(incidentId));
        }
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.spacingBase,
          horizontal: AppDimens.spacing2Xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail ảnh sự cố
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              child: SizedBox(
                width: 60,
                height: 60,
                child: image == null
                    ? const ColoredBox(
                        color: AppColors.surfaceSubtle,
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.textTertiary,
                          size: 24,
                        ),
                      )
                    : AppCachedImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        memCacheWidth: 180,
                      ),
              ),
            ),
            const SizedBox(width: AppDimens.spacingBase),
            // Chi tiết sự cố
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          incident['incident_type']?['name']?.toString() ??
                              'Sự cố đô thị',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimens.spacingSm),
                      AppStatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    incident['description']?.toString() ??
                        'Đang cập nhật thông tin',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.spacingXs),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
