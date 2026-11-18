import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_map_tile_style.dart';
import '../../data/models/interested_area_model.dart';

class InterestedAreaEditor extends StatefulWidget {
  const InterestedAreaEditor({
    super.key,
    this.area,
    required this.onSave,
    required this.onSearch,
  });

  final InterestedAreaModel? area;
  final Future<void> Function(String, double, double, int, bool) onSave;
  final Future<List<Map<String, dynamic>>> Function(
    String,
    double,
    double,
  ) onSearch;

  @override
  State<InterestedAreaEditor> createState() => _InterestedAreaEditorState();
}

class _InterestedAreaEditorState extends State<InterestedAreaEditor> {
  final searchController = TextEditingController();
  final mapController = MapController();
  Timer? debounce;
  late LatLng center;
  late double radius;
  bool notificationsEnabled = true;
  bool saving = false;
  bool searching = false;
  List<Map<String, dynamic>> suggestions = [];
  String selectedAreaName = '';
  String? error;

  @override
  void initState() {
    super.initState();
    final area = widget.area;
    selectedAreaName = area?.name ?? '';
    searchController.text = area?.name ?? '';
    center = LatLng(area?.latitude ?? 21.0285, area?.longitude ?? 105.8542);
    radius = (area?.radiusM ?? 1000).toDouble();
    notificationsEnabled = area?.notificationsEnabled ?? true;
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    mapController.dispose();
    super.dispose();
  }

  void searchChanged(String value) {
    debounce?.cancel();
    selectedAreaName = '';
    if (error != null) setState(() => error = null);
    if (value.trim().length < 2) {
      setState(() => suggestions = []);
      return;
    }
    debounce = Timer(const Duration(milliseconds: 450), () => search(value));
  }

  Future<void> search(String value) async {
    if (value.trim().length < 2) return;
    setState(() {
      searching = true;
      error = null;
    });
    try {
      final result = await widget.onSearch(
        value.trim(),
        center.latitude,
        center.longitude,
      );
      if (mounted) {
        setState(() {
          suggestions = result;
          if (result.isEmpty) {
            error = 'Không tìm thấy địa điểm. Hãy thử tên đầy đủ hơn.';
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Không thể tìm địa điểm lúc này');
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  void selectPlace(Map<String, dynamic> place) {
    final point = LatLng(
      (place['latitude'] as num).toDouble(),
      (place['longitude'] as num).toDouble(),
    );
    setState(() {
      center = point;
      selectedAreaName = place['name']?.toString() ?? '';
      suggestions = [];
      searchController.text = place['address']?.toString().isNotEmpty == true
          ? place['address'].toString()
          : place['name'].toString();
      error = null;
    });
    mapController.move(point, 16);
    FocusScope.of(context).unfocus();
  }

  Future<void> locate() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    final point = LatLng(position.latitude, position.longitude);
    if (!mounted) {
      return;
    }
    setState(() => center = point);
    mapController.move(point, 16);
  }

  Future<void> save() async {
    final areaName = selectedAreaName.trim().isNotEmpty
        ? selectedAreaName.trim()
        : searchController.text.trim();
    if (areaName.length < 2) {
      setState(() => error = 'Vui lòng tìm hoặc chọn một địa điểm');
      return;
    }
    setState(() { saving = true; error = null; });
    try {
      await widget.onSave(
        areaName,
        center.latitude,
        center.longitude,
        radius.round(),
        notificationsEnabled,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => error = 'Không thể lưu khu vực');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: AppDimens.spacingMd,
          right: AppDimens.spacingMd,
          top: AppDimens.spacingMd,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppDimens.spacingMd,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(widget.area == null ? 'Thêm khu vực' : 'Chỉnh sửa khu vực', style: AppTextStyles.titleMedium)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              TextField(
                controller: searchController,
                onChanged: searchChanged,
                onSubmitted: search,
                decoration: InputDecoration(
                  labelText: 'Tìm địa chỉ hoặc địa điểm',
                  hintText: 'Ví dụ: Bệnh viện Bạch Mai',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searching
                      ? const Padding(padding: EdgeInsets.all(AppDimens.spacingBase), child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                ),
              ),
              if (suggestions.isNotEmpty)
                Material(
                  color: AppColors.surface,
                  child: Column(
                    children: suggestions.map((place) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                      title: Text(place['name']?.toString() ?? 'Địa điểm'),
                      subtitle: Text(place['address']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => selectPlace(place),
                    )).toList(),
                  ),
                ),
              if (error != null) ...[
                const SizedBox(height: AppDimens.spacingXs),
                Text(
                  error!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppDimens.spacingMd),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: SizedBox(
                  height: 220,
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(initialCenter: center, initialZoom: 14, onTap: (_, point) => setState(() => center = point)),
                    children: [
                      TileLayer(urlTemplate: AppConfig.mapTileUrl, userAgentPackageName: 'com.example.urban_issue_app', tileBuilder: AppMapTileStyle.lightMuted),
                      CircleLayer(circles: [CircleMarker(point: center, radius: radius, useRadiusInMeter: true, color: AppColors.primaryLight, borderColor: AppColors.primary, borderStrokeWidth: 2)]),
                      MarkerLayer(markers: [Marker(point: center, width: 40, height: 40, child: const Icon(Icons.location_pin, color: AppColors.primary, size: 40))]),
                    ],
                  ),
                ),
              ),
              TextButton.icon(onPressed: locate, icon: const Icon(Icons.my_location), label: const Text('Dùng vị trí hiện tại')),
              Text('Bán kính ${(radius / 1000).toStringAsFixed(1)} km', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
              Slider(value: radius, min: 200, max: 10000, divisions: 49, label: '${radius.round()} m', onChanged: (value) => setState(() => radius = value)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Nhận cảnh báo khu vực'), subtitle: const Text('Thông báo khi có sự cố mới trong phạm vi này'), value: notificationsEnabled, onChanged: (value) => setState(() => notificationsEnabled = value)),
              const SizedBox(height: AppDimens.spacingSm),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Đang lưu...' : 'Lưu khu vực'))),
            ],
          ),
        ),
      );
}
