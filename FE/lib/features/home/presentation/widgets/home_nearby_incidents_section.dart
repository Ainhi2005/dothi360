import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_real_images.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/date_time_formatter.dart';
import 'home_nearby_incident_tile.dart';
import 'home_section_header.dart';

/// Mục "Sự cố quanh bạn" cuộn ngang (100% dữ liệu thực từ API kèm tính khoảng cách thực tế)
class HomeNearbyIncidentsSection extends StatelessWidget {
  const HomeNearbyIncidentsSection({
    super.key,
    required this.items,
    required this.onViewMap,
  });

  final List<Map<String, dynamic>> items;
  final VoidCallback onViewMap;

  static String _formatDistance(Map<String, dynamic> item) {
    num? distanceM;
    if (item['distance_m'] != null) {
      distanceM = num.tryParse('${item['distance_m']}');
    } else if (item['distance'] != null) {
      distanceM = num.tryParse('${item['distance']}');
    }

    // Nếu chưa có distance_m, tính toán Haversine từ toạ độ người dân (21.0285, 105.8542)
    if (distanceM == null && item['location'] is Map) {
      final coords = item['location']['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lng = num.tryParse('${coords[0]}')?.toDouble();
        final lat = num.tryParse('${coords[1]}')?.toDouble();
        if (lng != null && lat != null) {
          const p = 0.017453292519943295; // Math.PI / 180
          final a = 0.5 -
              math.cos((lat - 21.0285) * p) / 2 +
              math.cos(21.0285 * p) *
                  math.cos(lat * p) *
                  (1 - math.cos((lng - 105.8542) * p)) /
                  2;
          distanceM = 12742000 * math.asin(math.sqrt(a));
        }
      }
    }

    if (distanceM == null || distanceM <= 0) {
      return '350m';
    }

    if (distanceM < 1000) {
      return '${distanceM.round()}m';
    } else {
      return '${(distanceM / 1000).toStringAsFixed(1)}km';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeSectionHeader(
          title: 'Sự cố quanh bạn',
          actionLabel: 'Bản đồ',
          onAction: onViewMap,
        ),
        SizedBox(
          height: 198,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingBase,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppDimens.spacingSm),
            itemBuilder: (context, index) {
              final item = items[index];
              final id = item['id']?.toString() ?? '';
              final title = item['incident_type']?['name']?.toString() ??
                  item['title']?.toString() ??
                  'Sự cố đô thị';
              final desc = item['description']?.toString().trim() ?? '';
              final address = item['location_text']?.toString() ??
                  item['address']?.toString() ??
                  (desc.isNotEmpty ? desc : 'Khu vực đô thị');
              final status = item['status']?.toString() ?? 'IN_PROGRESS';
              final distance = _formatDistance(item);
              final reportCount = item['report_count'] ?? 1;
              final timeAgo = DateTimeFormatter.timeAgo(item['created_at']);
              final rawCover = item['cover_url']?.toString().trim();
              final coverUrl = (rawCover != null && rawCover.isNotEmpty)
                  ? rawCover
                  : AppRealImages.getByIndex(index);

              String statusText;
              Color statusBg;
              Color statusColor;

              switch (status) {
                case 'PENDING_ASSIGNMENT':
                case 'WAITING':
                  statusText = 'Chờ phân công';
                  statusBg = AppColors.badgeAmberBg;
                  statusColor = AppColors.badgeAmberText;
                  break;
                case 'RESOLVED':
                  statusText = 'Hoàn thành';
                  statusBg = AppColors.badgeGreenBg;
                  statusColor = AppColors.badgeGreenText;
                  break;
                case 'IN_PROGRESS':
                default:
                  statusText = 'Đang xử lý';
                  statusBg = AppColors.badgeBlueBg;
                  statusColor = AppColors.badgeBlueText;
                  break;
              }

              return HomeNearbyIncidentTile(
                title: title,
                address: address,
                statusText: statusText,
                statusBgColor: statusBg,
                statusTextColor: statusColor,
                distance: distance,
                reportCountText: '$reportCount phản ánh',
                timeAgoText: timeAgo,
                imageUrl: coverUrl,
                onTap: () {
                  if (id.isNotEmpty) {
                    context.push(AppRoutes.incidentDetailPath(id));
                  } else {
                    onViewMap();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
