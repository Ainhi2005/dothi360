import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/interested_area_model.dart';

class InterestedAreaCard extends StatelessWidget {
  const InterestedAreaCard({
    super.key,
    required this.area,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final InterestedAreaModel area;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final radius = (area.radiusM / 1000).toStringAsFixed(
      area.radiusM % 1000 == 0 ? 0 : 1,
    );

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingMd),
          child: Row(
            children: [
              Container(
                width: AppDimens.spacingXxl,
                height: AppDimens.spacingXxl,
                decoration: BoxDecoration(
                  color: AppColors.homeMint,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimens.spacingBase),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            area.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (area.notificationsEnabled)
                          const Icon(
                            Icons.notifications_active_outlined,
                            size: AppDimens.iconSizeSm,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.spacingXs),
                    Text(
                      'Bán kính $radius km · ${area.incidentCount} sự cố',
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (area.newCount > 0)
                      Text(
                        '${area.newCount} sự cố mới trong 24 giờ',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.homeOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Ngừng theo dõi'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
