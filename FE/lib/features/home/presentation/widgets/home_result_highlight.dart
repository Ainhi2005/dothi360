import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_badge.dart';

/// Khối nổi bật kết quả xử lý sự cố vừa hoàn thành (Civic Resolution Highlight)
class HomeResultHighlight extends StatelessWidget {
  const HomeResultHighlight({
    super.key,
    required this.incident,
    required this.onViewAll,
  });

  final Map<String, dynamic>? incident;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    if (incident == null) return const SizedBox.shrink();
    final image = incident!['cover_url']?.toString();
    final type =
        incident!['incident_type']?['name']?.toString() ?? 'Sự cố đô thị';
    final incidentId = incident!['id']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Vừa giải quyết xong',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.spacingXs),
        AppCard(
          padding: EdgeInsets.zero,
          onTap: () {
            if (incidentId.isNotEmpty) {
              context.push(AppRoutes.incidentDetailPath(incidentId));
            }
          },
          child: Row(
            children: [
              SizedBox(
                width: 90,
                height: 80,
                child: AppCachedImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  memCacheWidth: 300,
                  placeholderIcon: Icons.task_alt,
                ),
              ),
              const SizedBox(width: AppDimens.spacingBase),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppDimens.spacingSm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const AppStatusBadge(
                        status: 'RESOLVED',
                        customLabel: 'Đã hoàn thành',
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: AppDimens.spacingBase),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
