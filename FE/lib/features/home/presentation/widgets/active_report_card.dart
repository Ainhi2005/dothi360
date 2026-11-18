import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/incident_status.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_status_badge.dart';

/// Thẻ hiển thị phản ánh đang xử lý với thanh tiến độ 5 bước
class ActiveReportCard extends StatelessWidget {
  const ActiveReportCard({super.key, required this.report});

  final Map<String, dynamic>? report;

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return const AppCard(
        child: Text(
          'Bạn chưa có phản ánh nào đang xử lý.',
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    final incident = Map<String, dynamic>.from(report!['incident'] ?? const {});
    final status = incident['status']?.toString() ?? 'PENDING_ASSIGNMENT';
    final media = List<Map<String, dynamic>>.from(report!['media'] ?? const []);
    final image = media.isEmpty ? null : media.first['file_url']?.toString();
    final incidentId = incident['id']?.toString() ?? '';

    final progress = switch (status) {
      IncidentStatus.resolved => 5,
      IncidentStatus.pendingVerification => 4,
      IncidentStatus.inProgress => 3,
      IncidentStatus.accepted || IncidentStatus.assigned => 2,
      _ => 1,
    };

    return AppCard(
      onTap: () {
        if (incidentId.isNotEmpty) {
          context.push(AppRoutes.incidentDetailPath(incidentId));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: image == null
                      ? const ColoredBox(
                          color: AppColors.surfaceSubtle,
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.textTertiary,
                            size: 28,
                          ),
                        )
                      : AppCachedImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          memCacheWidth: 240,
                        ),
                ),
              ),
              const SizedBox(width: AppDimens.spacingBase),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident['incident_type']?['name']?.toString() ??
                          'Sự cố đô thị',
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incident['description']?.toString() ?? '',
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    AppStatusBadge(status: status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingBase),
          // Thanh tiến độ 5 nấc
          Row(
            children: List.generate(5, (index) {
              final isReached = index < progress;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isReached
                            ? AppColors.primary
                            : AppColors.surfaceSubtle,
                        border: Border.all(
                          color:
                              isReached ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: isReached
                          ? const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    if (index < 4)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index + 1 < progress
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Đã gửi', style: AppTextStyles.caption),
              Text('Tiếp nhận', style: AppTextStyles.caption),
              Text('Xử lý', style: AppTextStyles.caption),
              Text('Nghiệm thu', style: AppTextStyles.caption),
              Text('Xong', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
