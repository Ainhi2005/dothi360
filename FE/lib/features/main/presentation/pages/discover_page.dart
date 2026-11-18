import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_map_tile_style.dart';
import '../widgets/incident_marker_cluster.dart';
import '../widgets/map_floating_search_bar.dart';
import '../widgets/map_incident_preview_card.dart';
import '../widgets/map_status_legend.dart';

/// Tab Khám phá sự cố đô thị (Kiến trúc Map-First toàn màn hình)
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allItems = [];
  Map<String, dynamic>? _selectedIncident;
  Position? _currentPosition;

  String _statusFilter = 'ALL';
  String _searchQuery = '';

  Timer? _debounce;
  bool _loading = false;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkInitialLocation();
  }

  Future<void> _checkInitialLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            timeLimit: Duration(seconds: 4),
          ),
        );
        if (mounted) {
          setState(() => _currentPosition = position);
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            14.5,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _loadIncidents(LatLngBounds bounds) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await DioClient().dio.get(
        '/incidents/map/bbox',
        queryParameters: {
          'minLng': bounds.west,
          'minLat': bounds.south,
          'maxLng': bounds.east,
          'maxLat': bounds.north,
        },
      );
      if (mounted) {
        final data = response.data['data'];
        setState(() {
          _allItems = List<Map<String, dynamic>>.from(data is List ? data : []);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể tải sự cố khu vực này');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _moveToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Vui lòng cấp quyền vị trí để định vị xung quanh bạn.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 6),
        ),
      );
      if (mounted) {
        setState(() => _currentPosition = position);
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15,
        );
        await _loadIncidents(_mapController.camera.visibleBounds);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa thể lấy vị trí GPS hiện tại.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    return _allItems.where((item) {
      // 1. Lọc theo trạng thái
      if (_statusFilter != 'ALL') {
        final status = item['status']?.toString() ?? '';
        if (_statusFilter == 'ACCEPTED' &&
            status != 'ASSIGNED' &&
            status != 'ACCEPTED') {
          return false;
        }
        if (_statusFilter != 'ACCEPTED' && status != _statusFilter) {
          return false;
        }
      }

      // 2. Lọc theo tìm kiếm từ khóa
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final type =
            (item['incident_type']?['name']?.toString() ?? '').toLowerCase();
        final desc = (item['description']?.toString() ?? '').toLowerCase();
        if (!type.contains(q) && !desc.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  String? _getDistanceToIncident(Map<String, dynamic> incident) {
    if (_currentPosition == null) return null;
    final coordinates = (incident['location']?['coordinates'] as List?) ?? [];
    if (coordinates.length < 2) return null;
    final lat = (coordinates[1] as num).toDouble();
    final lng = (coordinates[0] as num).toDouble();

    final meters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );

    if (meters < 1000) {
      return 'Cách ${meters.round()}m';
    } else {
      return 'Cách ${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. BẢN ĐỒ TOÀN MÀN HÌNH (MAP-FIRST CANVAS)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(21.0285, 105.8542),
              initialZoom: 13.5,
              onMapReady: () =>
                  _loadIncidents(_mapController.camera.visibleBounds),
              onPositionChanged: (camera, _) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 400),
                  () => _loadIncidents(camera.visibleBounds),
                );
              },
              onTap: (_, __) {
                FocusScope.of(context).unfocus();
                if (_selectedIncident != null) {
                  setState(() => _selectedIncident = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.mapTileUrl,
                userAgentPackageName: 'com.example.urban_issue_app',
                tileBuilder: AppMapTileStyle.lightMuted,
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(AppConfig.mapAttribution),
                ],
              ),
              IncidentMarkerCluster(
                items: filteredItems,
                onIncidentTap: (item) {
                  setState(() => _selectedIncident = item);
                },
              ),
            ],
          ),

          // 2. KHỐI TÌM KIẾM & BỘ LỌC NỔI Ở ĐỈNH
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimens.spacingXs),
                  MapFloatingSearchBar(
                    searchController: _searchController,
                    selectedStatusFilter: _statusFilter,
                    onSearchChanged: (q) =>
                        setState(() => _searchQuery = q.trim()),
                    onFilterChanged: (f) => setState(() => _statusFilter = f),
                    onClearSearch: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                  const SizedBox(height: AppDimens.spacingSm),

                  // Thanh chú giải mini có thể thu gọn
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spacingSm + 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const MapStatusLegend(),
                        if (_loading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.spacingSm,
                              vertical: AppDimens.spacing2Xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusFull),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Đang đồng bộ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. NÚT ĐỊNH VỊ HIỆN TẠI (TỐI ƯU THAO TÁC 1 TAY)
          Positioned(
            right: AppDimens.spacingMd,
            bottom: _selectedIncident != null ? 175 : 24,
            child: Material(
              color: AppColors.surface,
              elevation: 3,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              child: InkWell(
                onTap: _locating ? null : _moveToCurrentLocation,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ),
          ),

          // 4. BOTTOM SHEET PREVIEW KHI CHẠM MARKER
          if (_selectedIncident != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: MapIncidentPreviewCard(
                incident: _selectedIncident!,
                distanceText: _getDistanceToIncident(_selectedIncident!),
                onClose: () => setState(() => _selectedIncident = null),
                onTap: () {
                  final id = _selectedIncident!['id'].toString();
                  context.push(AppRoutes.incidentDetailPath(id));
                },
              ),
            ),

          // 5. CẢNH BÁO LỖI NỔI
          if (_error != null)
            Positioned(
              top: 100,
              left: AppDimens.spacingMd,
              right: AppDimens.spacingMd,
              child: Material(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingMd,
                    vertical: AppDimens.spacingSm,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: AppDimens.spacingSm),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _loadIncidents(_mapController.camera.visibleBounds),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
