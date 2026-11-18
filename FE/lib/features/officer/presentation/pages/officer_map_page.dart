import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_map_tile_style.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../data/models/officer_assignment_model.dart';
import '../providers/officer_provider.dart';

/// Màn hình Bản đồ nhiệm vụ Cán bộ chuẩn format Grab UI của Người dân
class OfficerMapPage extends ConsumerStatefulWidget {
  const OfficerMapPage({super.key});

  @override
  ConsumerState<OfficerMapPage> createState() => _OfficerMapPageState();
}

class _OfficerMapPageState extends ConsumerState<OfficerMapPage> {
  final MapController _mapController = MapController();
  OfficerAssignmentModel? _selectedTask;
  String _filter = 'all'; // 'all' or 'urgent'

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(officerAssignmentsProvider('all'));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: assignmentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.grabGreen,
          ),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: AppDimens.spacingSm),
              const Text('Không thể tải dữ liệu bản đồ'),
              const SizedBox(height: AppDimens.spacingSm),
              AppButton(
                label: 'Tải lại bản đồ',
                onPressed: () => ref.invalidate(officerAssignmentsProvider('all')),
                isFullWidth: false,
                type: AppButtonType.secondary,
              ),
            ],
          ),
        ),
        data: (items) {
          final located = items
              .where((item) => item.latitude != null && item.longitude != null)
              .toList();

          final filtered = located.where((item) {
            if (_filter == 'urgent') {
              return item.isUrgent || item.isOverdue;
            }
            return true;
          }).toList();

          final center = filtered.isNotEmpty
              ? LatLng(filtered.first.latitude!, filtered.first.longitude!)
              : const LatLng(21.0285, 105.8542);

          return Stack(
            children: [
              // 1. Lớp Bản đồ Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 13.5,
                  onTap: (_, __) {
                    if (_selectedTask != null) {
                      setState(() => _selectedTask = null);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppConfig.mapTileUrl,
                    userAgentPackageName: 'com.example.urban_issue_app',
                    tileBuilder: AppMapTileStyle.lightMuted,
                  ),
                  MarkerLayer(
                    markers: filtered.map((item) {
                      final isSelected = _selectedTask?.id == item.id;
                      final isUrgent = item.isUrgent || item.isOverdue;
                      final color = isUrgent
                          ? AppColors.error
                          : (item.isWaiting ? AppColors.warning : AppColors.grabGreen);

                      return Marker(
                        point: LatLng(item.latitude!, item.longitude!),
                        width: isSelected ? 48 : 38,
                        height: isSelected ? 48 : 38,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedTask = item);
                            _mapController.move(
                              LatLng(item.latitude!, item.longitude!),
                              14.5,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadowSubtle,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isUrgent
                                  ? Icons.warning_amber_rounded
                                  : (item.isWaiting ? Icons.hourglass_top_rounded : Icons.build_rounded),
                              size: isSelected ? 24 : 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // 2. Thanh điều khiển nổi trên đầu bản đồ (Floating Control Bar)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingBase,
                    vertical: AppDimens.spacingSm,
                  ),
                  child: Row(
                    children: [
                      // Chip lọc danh sách
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowSearch,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MapFilterPill(
                              label: 'Tất cả (${located.length})',
                              isSelected: _filter == 'all',
                              onTap: () => setState(() => _filter = 'all'),
                            ),
                            const SizedBox(width: 4),
                            _MapFilterPill(
                              label: 'Khẩn cấp 🚨',
                              isSelected: _filter == 'urgent',
                              onTap: () => setState(() => _filter = 'urgent'),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Nút Tải lại bản đồ
                      InkWell(
                        onTap: () => ref.invalidate(officerAssignmentsProvider('all')),
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowSearch,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Thẻ nhiệm vụ nổi ở dưới chân bản đồ khi được chọn (Floating Task Preview Card)
              if (_selectedTask != null)
                Positioned(
                  left: AppDimens.spacingBase,
                  right: AppDimens.spacingBase,
                  bottom: AppDimens.spacingLg,
                  child: AppCard(
                    padding: const EdgeInsets.all(AppDimens.spacingMd),
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hàng tiêu đề + Đóng
                        Row(
                          children: [
                            AppStatusBadge(status: _selectedTask!.status),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedTask!.incidentTypeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _selectedTask = null),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Thông tin sự cố
                        Row(
                          children: [
                            if (_selectedTask!.coverUrl != null &&
                                _selectedTask!.coverUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: AppCachedImage(
                                    imageUrl: _selectedTask!.coverUrl!,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 150,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedTask!.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 12,
                                        color: AppColors.grabGreenDark,
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          'Hà Nội · ${_selectedTask!.reportCount} phản ánh',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textTertiary,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDimens.spacingSm),

                        // 2 Nút hành động chuẩn format Grab
                        Row(
                          children: [
                            // Nút chỉ đường
                            Expanded(
                              child: AppButton(
                                label: 'Chỉ đường',
                                icon: Icons.directions_rounded,
                                type: AppButtonType.secondary,
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse(
                                      'https://www.google.com/maps/dir/?api=1&destination=${_selectedTask!.latitude},${_selectedTask!.longitude}',
                                    ),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Nút mở nhiệm vụ
                            Expanded(
                              child: AppButton(
                                label: 'Mở nhiệm vụ',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () {
                                  context.push(
                                    AppRoutes.officerAssignmentPath(_selectedTask!.id),
                                    extra: _selectedTask,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MapFilterPill extends StatelessWidget {
  const _MapFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.grabGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
