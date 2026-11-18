import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import 'home_hero_header.dart';
import 'home_nearby_incidents_section.dart';
import 'home_news_alert_section.dart';
import 'home_resolved_section.dart';
import 'urban_utility_grid.dart';

/// Bố cục chính Trang chủ Người dân
class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.data,
    required this.onRefresh,
  });

  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final user = Map<String, dynamic>.from(data['user'] ?? const {});
    final community =
        List<Map<String, dynamic>>.from(data['community'] ?? const []);
    final areaAlert = data['area_alert'] == null
        ? null
        : Map<String, dynamic>.from(data['area_alert']);
    final notifications =
        List<Map<String, dynamic>>.from(data['notifications'] ?? const []);

    final nearbyActive = community
        .where(
          (item) =>
              !['RESOLVED', 'REJECTED', 'CANCELLED'].contains(item['status']),
        )
        .take(8)
        .toList();

    final resolved =
        community.where((item) => item['status'] == 'RESOLVED').toList();

    final fullName = user['full_name']?.toString().trim() ?? '';
    final shortName =
        fullName.isEmpty ? 'bạn' : fullName.split(RegExp(r'\s+')).last;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          // 1. Header Đô thị chuyên nghiệp chuẩn Super App
          SliverToBoxAdapter(
            child: HomeHeroHeader(
              name: shortName,
              avatarUrl: user['avatar_url']?.toString(),
              unread: int.tryParse('${data['unread']}') ?? 0,
              onWeather: () => context.push(AppRoutes.weatherAqi),
              onNotifications: () => context.push(AppRoutes.notifications),
              onSearch: () => context.go(AppRoutes.discover),
              onQuickReport: () => context.push(AppRoutes.createReport),
              onAvatarTap: () => context.push(AppRoutes.personalInfo),
            ),
          ),

          // 2. Nội dung cuộn chính
          SliverToBoxAdapter(
            child: ColoredBox(
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiện ích đô thị (Thẻ 2 hàng x 4 mục chuẩn theo ảnh và yêu cầu)
                  UrbanUtilityGrid(
                    onAiAssistant: () => context.push(AppRoutes.chat),
                    onEmergencyGuide: () => context.push(AppRoutes.guide),
                    onEmergencyContacts: () =>
                        context.push(AppRoutes.emergencyContacts),
                    onInterestedArea: () =>
                        context.push(AppRoutes.interestedAreas),
                    onWeather: () => context.push(AppRoutes.weatherAqi),
                    onFloodPoints: () => context.push(AppRoutes.floodPoints),
                    onDepartments: () => context.push(AppRoutes.departments),
                    onFeedback: () => context.push(AppRoutes.feedbacks),
                  ),

                  const SizedBox(height: AppDimens.spacingSm),

                  // 3. Carousel Thông tin & Cảnh báo (từ thông báo thực tế của hệ thống)
                  HomeNewsAlertSection(
                    areaAlert: areaAlert,
                    notifications: notifications,
                    onTapIncident: (incidentId) {
                      context.push(AppRoutes.incidentDetailPath(incidentId));
                    },
                    onViewAll: () => context.push(AppRoutes.notifications),
                  ),

                  const SizedBox(height: AppDimens.spacingSm),

                  // 4. Sự cố quanh bạn
                  HomeNearbyIncidentsSection(
                    items: nearbyActive,
                    onViewMap: () => context.go(AppRoutes.discover),
                  ),

                  const SizedBox(height: AppDimens.spacingSm),

                  // 5. Vừa giải quyết xong
                  HomeResolvedSection(
                    resolvedIncident:
                        resolved.isNotEmpty ? resolved.first : null,
                    onViewAll: () => context.push(AppRoutes.resolvedIncidents),
                  ),

                  const SizedBox(height: AppDimens.spacingXl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
