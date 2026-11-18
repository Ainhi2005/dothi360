import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'home_incident_carousel.dart';

/// Mục hiển thị các sự cố đang diễn ra xung quanh người dân
class HomeAreaInformation extends StatelessWidget {
  const HomeAreaInformation({
    super.key,
    required this.items,
    required this.onViewAll,
  });

  final List<Map<String, dynamic>> items;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sự cố gần bạn',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(
                  Icons.map_outlined,
                  size: AppDimens.iconSizeSm,
                ),
                label: const Text('Bản đồ'),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingXs),
          HomeIncidentCarousel(items: items),
        ],
      );
}
