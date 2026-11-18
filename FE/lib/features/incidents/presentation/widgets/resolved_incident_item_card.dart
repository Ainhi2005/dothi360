import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../core/widgets/app_cached_image.dart';

/// Thẻ sự cố đã hoàn thành xử lý trong danh sách "Vừa giải quyết xong"
class ResolvedIncidentItemCard extends StatelessWidget {
  const ResolvedIncidentItemCard({
    super.key,
    required this.incident,
    required this.onTap,
  });

  final Map<String, dynamic> incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = incident['incident_type']?['name']?.toString() ??
        incident['title']?.toString() ??
        incident['description']?.toString() ??
        'Sự cố đô thị';
    final desc = incident['resolution_note']?.toString() ??
        incident['description']?.toString() ??
        'Đã xử lý xong và hoàn trả mặt bằng sạch sẽ.';
    final unit = incident['assigned_department']?['name']?.toString() ??
        'Đội xử lý sự cố đô thị';
    final time = DateTimeFormatter.timeAgo(
      incident['resolved_at'] ?? incident['updated_at'],
    );
    final imageUrl = incident['cover_url']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.spacingSm + 2),
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingSm + 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh đại diện hoàn thành
              AppCachedImage(
                imageUrl: imageUrl,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                memCacheWidth: 250,
                placeholderIcon: Icons.check_circle_outline,
              ),
              const SizedBox(width: AppDimens.spacingSm + 2),
              // Nội dung chi tiết
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$unit • $time',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grabGreenDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.textTertiary,
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
