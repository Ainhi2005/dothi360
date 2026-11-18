import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../incidents/presentation/widgets/incident_media_gallery.dart';
import '../../data/models/officer_assignment_model.dart';

class OfficerIncidentContextCard extends StatelessWidget {
  const OfficerIncidentContextCard({
    required this.assignment,
    super.key,
  });

  final OfficerAssignmentModel assignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mô tả & Hiện trường ban đầu',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Text(
                  '${assignment.reportCount} lượt phản ánh',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSm),
          Text(
            assignment.description.trim().isNotEmpty
                ? assignment.description
                : 'Chưa có mô tả chi tiết từ người dân.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          if (assignment.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: AppDimens.spacingMd),
            IncidentMediaGallery(imageUrls: assignment.mediaUrls),
          ] else if (assignment.coverUrl != null) ...[
            const SizedBox(height: AppDimens.spacingMd),
            IncidentMediaGallery(imageUrls: [assignment.coverUrl!]),
          ],
          const Divider(height: AppDimens.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phương thức giao việc',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      assignment.reason?.trim().isNotEmpty == true
                          ? assignment.reason!
                          : 'Điều phối tự động qua AI & Hệ thống',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push(
                  AppRoutes.incidentDetailPath(assignment.incidentId),
                ),
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Hồ sơ công khai',
                  style: AppTextStyles.linkText,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(50, 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
