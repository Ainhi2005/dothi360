import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_status_badge.dart';

/// Thẻ sự cố lân cận trong danh sách cuộn ngang (Civic Incident Mini Card)
class HomeIncidentCard extends StatelessWidget {
  const HomeIncidentCard({
    super.key,
    required this.incident,
    this.width = AppDimens.homeIncidentCardWidth,
  });

  final Map<String, dynamic> incident;
  final double width;

  @override
  Widget build(BuildContext context) {
    final image = incident['cover_url']?.toString();
    final status = incident['status']?.toString() ?? 'PENDING_ASSIGNMENT';
    final type =
        incident['incident_type']?['name']?.toString() ?? 'Sự cố đô thị';
    final reportCount = incident['report_count'] ?? 1;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.incidentDetailPath(incident['id'].toString()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh bìa sự cố
              SizedBox(
                height: 88,
                width: double.infinity,
                child: AppCachedImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  memCacheWidth: 350,
                  placeholderIcon: Icons.image_outlined,
                ),
              ),
              // Thông tin sự cố
              Padding(
                padding: const EdgeInsets.all(AppDimens.spacingSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: AppStatusBadge(
                            status: status,
                            showDot: false,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$reportCount báo',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
