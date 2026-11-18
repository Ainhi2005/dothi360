import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../core/widgets/app_cached_image.dart';
import 'home_section_header.dart';

/// Mục "Vừa giải quyết xong" trên Trang chủ hiển thị sự cố đô thị hoàn thành gần nhất
class HomeResolvedSection extends StatelessWidget {
  const HomeResolvedSection({
    super.key,
    required this.onViewAll,
    this.resolvedIncident,
  });

  final VoidCallback onViewAll;
  final Map<String, dynamic>? resolvedIncident;

  @override
  Widget build(BuildContext context) {
    if (resolvedIncident == null) {
      return const SizedBox.shrink();
    }

    final title = resolvedIncident!['incident_type']?['name']?.toString() ??
        resolvedIncident!['title']?.toString() ??
        resolvedIncident!['description']?.toString() ??
        'Sự cố đô thị';
    final desc = resolvedIncident!['resolution_note']?.toString() ??
        resolvedIncident!['description']?.toString() ??
        'Đã xử lý xong và hoàn trả mặt bằng sạch sẽ';
    final unit = resolvedIncident!['assigned_department']?['name']?.toString() ??
        'Đội xử lý sự cố đô thị';
    final time = DateTimeFormatter.timeAgo(
      resolvedIncident!['resolved_at'] ?? resolvedIncident!['updated_at'],
    );
    final imageUrl = resolvedIncident!['cover_url']?.toString();
    final id = resolvedIncident!['id']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          HomeSectionHeader(
            title: 'Vừa giải quyết xong',
            actionLabel: 'Xem tất cả',
            onAction: onViewAll,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingBase,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowSubtle,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  if (id.isNotEmpty) {
                    context.push(AppRoutes.incidentDetailPath(id));
                  } else {
                    onViewAll();
                  }
                },
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Ảnh thumbnail vuông
                      AppCachedImage(
                        imageUrl: imageUrl,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        memCacheWidth: 200,
                        placeholderIcon: Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 12),
                      // Thông tin chi tiết
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.badgeGreenBg,
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusFull,
                                    ),
                                  ),
                                  child: const Text(
                                    'Hoàn thành',
                                    style: TextStyle(
                                      color: AppColors.badgeGreenText,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$unit • $time',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.grabGreenDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
