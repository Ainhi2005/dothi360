import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_map_tile_style.dart';
import '../../data/datasources/incident_location_remote_datasource.dart';
import '../../data/models/incident_location_selection.dart';

class IncidentLocationPickerPage extends StatefulWidget {
  const IncidentLocationPickerPage({this.initial, super.key});

  final IncidentLocationSelection? initial;

  @override
  State<IncidentLocationPickerPage> createState() =>
      _IncidentLocationPickerPageState();
}

class _IncidentLocationPickerPageState
    extends State<IncidentLocationPickerPage> {
  final _searchController = TextEditingController();
  final _mapController = MapController();
  final _dataSource = IncidentLocationRemoteDataSource();
  Timer? _debounce;
  late LatLng _point;
  String? _address;
  String _source = 'MAP';
  bool _searching = false;
  bool _locating = false;
  String? _searchError;
  List<Map<String, dynamic>> _results = const [];

  @override
  void initState() {
    super.initState();
    _point = widget.initial?.point ?? const LatLng(21.0285, 105.8542);
    _address = widget.initial?.address;
    _source = widget.initial?.source ?? 'MAP';
    _searchController.text = _address ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await _dataSource.search(
        query.trim(),
        latitude: _point.latitude,
        longitude: _point.longitude,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _searchError = results.isEmpty
              ? 'Không tìm thấy địa điểm phù hợp. Hãy thử địa chỉ đầy đủ hơn.'
              : null;
        });
      }
    } on DioException catch (error) {
      if (!mounted) return;
      if (await _searchOnDevice(query.trim())) return;
      if (!mounted) return;
      final data = error.response?.data;
      setState(() {
        _results = const [];
        _searchError = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Không thể tìm địa điểm lúc này. Bạn có thể chạm trực tiếp trên bản đồ.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searchError =
            'Không thể tìm địa điểm lúc này. Bạn có thể chạm trực tiếp trên bản đồ.';
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<bool> _searchOnDevice(String query) async {
    try {
      final locations = await Geocoding().locationFromAddress(query);
      if (!mounted || locations.isEmpty) return false;
      final results = locations.take(5).map((location) => <String, dynamic>{
            'id': 'device-${location.latitude}-${location.longitude}',
            'name': query,
            'address': query,
            'latitude': location.latitude,
            'longitude': location.longitude,
            'type': 'device_geocoder',
          }).toList();
      setState(() {
        _results = results;
        _searchError = null;
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void _selectResult(Map<String, dynamic> result) {
    final point = LatLng(
      (result['latitude'] as num).toDouble(),
      (result['longitude'] as num).toDouble(),
    );
    final address = result['address']?.toString();
    setState(() {
      _point = point;
      _address = address?.isNotEmpty == true
          ? address
          : result['name']?.toString();
      _source = 'SEARCH';
      _results = const [];
      _searchError = null;
      _searchController.text = _address ?? '';
    });
    _mapController.move(point, 16);
    FocusScope.of(context).unfocus();
  }

  Future<void> _selectMapPoint(LatLng point) async {
    setState(() {
      _point = point;
      _source = 'MAP';
      _address = null;
    });
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (!mounted || places.isEmpty) return;
      final place = places.first;
      final address = [place.street, place.subAdministrativeArea, place.administrativeArea]
          .whereType<String>()
          .where((part) => part.trim().isNotEmpty)
          .join(', ');
      setState(() {
        _address = address;
        _searchController.text = address;
      });
    } catch (_) {}
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Ứng dụng chưa được cấp quyền vị trí.');
      }
      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      await _selectMapPoint(point);
      _source = 'GPS';
      _mapController.move(point, 16);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    context.pop(IncidentLocationSelection(
      point: _point,
      address: _address,
      source: _source,
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Chọn vị trí sự cố')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.spacingMd),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onSubmitted: _search,
                    decoration: InputDecoration(
                      labelText: 'Tìm địa chỉ hoặc địa điểm',
                      hintText: 'Ví dụ: 45 Phan Văn Trường, Cầu Giấy',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(AppDimens.spacingBase),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                  ),
                  if (_results.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 190),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined,
                                color: AppColors.primary),
                            title: Text(result['name']?.toString() ?? 'Địa điểm'),
                            subtitle: Text(
                              result['address']?.toString() ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectResult(result),
                          );
                        },
                      ),
                    ),
                  if (_searchError != null) ...[
                    const SizedBox(height: AppDimens.spacingXs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: AppDimens.iconSizeSm,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppDimens.spacingXs),
                        Expanded(
                          child: Text(
                            _searchError!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _point,
                  initialZoom: 15,
                  onTap: (_, point) => _selectMapPoint(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppConfig.mapTileUrl,
                    userAgentPackageName: 'com.example.urban_issue_app',
                    tileBuilder: AppMapTileStyle.lightMuted,
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: _point,
                      width: 48,
                      height: 48,
                      child: const Icon(Icons.location_pin,
                          color: AppColors.primary, size: 48),
                    ),
                  ]),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                AppDimens.spacingMd,
                AppDimens.spacingSm,
                AppDimens.spacingMd,
                MediaQuery.paddingOf(context).bottom + AppDimens.spacingSm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_address ?? 'Vị trí được ghim trên bản đồ',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppDimens.spacingSm),
                  Row(children: [
                    OutlinedButton.icon(
                      onPressed: _locating ? null : _useCurrentLocation,
                      icon: _locating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: const Text('Vị trí hiện tại'),
                    ),
                    const SizedBox(width: AppDimens.spacingSm),
                    Expanded(
                      child: FilledButton(
                        onPressed: _confirm,
                        child: const Text('Xác nhận vị trí sự cố'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      );
}
