import 'package:flutter/material.dart';

import '../../../../core/constants/app_real_images.dart';
import '../../../../core/theme/app_dimens.dart';
import 'home_news_banner_card.dart';
import 'home_section_header.dart';

/// Mục "Thông tin & Cảnh báo" dạng carousel (100% dữ liệu thực từ thông báo hệ thống)
class HomeNewsAlertSection extends StatelessWidget {
  const HomeNewsAlertSection({
    super.key,
    required this.onViewAll,
    this.onTapIncident,
    this.areaAlert,
    this.notifications = const [],
  });

  final VoidCallback onViewAll;
  final ValueChanged<String>? onTapIncident;
  final Map<String, dynamic>? areaAlert;
  final List<Map<String, dynamic>> notifications;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> banners = [];

    if (areaAlert != null) {
      final alertTitle = areaAlert!['title']?.toString();
      final alertMessage = areaAlert!['message']?.toString() ??
          areaAlert!['body']?.toString() ??
          '';
      if (alertTitle != null && alertTitle.isNotEmpty) {
        final alertData = areaAlert!['data'] is Map ? (areaAlert!['data'] as Map) : null;
        final customTag = alertData?['tag']?.toString();
        final incidentId = (alertData?['incident_id'] ?? areaAlert!['incident_id'] ?? '').toString();
        banners.add({
          'title': alertTitle,
          'subtitle': alertMessage,
          'tag': (customTag != null && customTag.isNotEmpty) ? customTag : 'Cảnh báo',
          'imageUrl': areaAlert!['image_url']?.toString() ??
              alertData?['image_url']?.toString() ??
              AppRealImages.incidentFlood,
          'incidentId': incidentId,
        });
      }
    }

    final areaAlertId = areaAlert?['id']?.toString();
    for (final item in notifications) {
      final itemId = item['id']?.toString();
      if (areaAlertId != null && itemId != null && areaAlertId == itemId) {
        continue;
      }
      final title = item['title']?.toString() ?? '';
      if (title.isEmpty) continue;
      final subtitle = item['message']?.toString() ??
          item['body']?.toString() ??
          '';
      final dataMap = item['data'] is Map ? (item['data'] as Map) : null;
      final customTag = dataMap?['tag']?.toString();
      final type = item['type']?.toString().toUpperCase() ?? '';
      final tag = (customTag != null && customTag.isNotEmpty)
          ? customTag
          : (type == 'EMERGENCY'
              ? 'Khẩn cấp'
              : (type == 'ALERT' || type == 'AREA_WARNING'
                  ? 'Cảnh báo'
                  : 'Tin đô thị'));
      final image = item['image_url']?.toString() ??
          item['cover_url']?.toString() ??
          dataMap?['image_url']?.toString() ??
          dataMap?['cover_url']?.toString() ??
          AppRealImages.getByIndex(banners.length);
      final incidentId = (dataMap?['incident_id'] ?? item['incident_id'] ?? '').toString();

      banners.add({
        'title': title,
        'subtitle': subtitle,
        'tag': tag,
        'imageUrl': image,
        'incidentId': incidentId,
      });
    }

    final displayBanners = banners.take(5).toList();

    if (displayBanners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeSectionHeader(
          title: 'Thông tin & Cảnh báo',
          actionLabel: 'Xem tất cả',
          onAction: onViewAll,
        ),
        SizedBox(
          height: 205,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingBase,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: displayBanners.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppDimens.spacingBase),
            itemBuilder: (context, index) {
              final banner = displayBanners[index];
              return HomeNewsBannerCard(
                title: banner['title']!,
                subtitle: banner['subtitle']!,
                tag: banner['tag']!,
                imageUrl: banner['imageUrl']!,
                onTap: () {
                  final incidentId = banner['incidentId'];
                  if (incidentId != null && incidentId.isNotEmpty && onTapIncident != null) {
                    onTapIncident!(incidentId);
                  } else {
                    onViewAll();
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
