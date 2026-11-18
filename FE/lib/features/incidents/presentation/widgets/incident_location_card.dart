import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_map_tile_style.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Thẻ bản đồ vị trí sự cố (Khối phụ gọn gàng)
class IncidentLocationCard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? address;

  const IncidentLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  State<IncidentLocationCard> createState() => _IncidentLocationCardState();
}

class _IncidentLocationCardState extends State<IncidentLocationCard> {
  String? _resolvedAddress;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    if (widget.address != null && widget.address!.isNotEmpty) {
      setState(() => _resolvedAddress = widget.address);
      return;
    }
    try {
      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(
        widget.latitude,
        widget.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.street?.isNotEmpty ?? false) p.street!,
          if (p.subLocality?.isNotEmpty ?? false) p.subLocality!,
          if (p.subAdministrativeArea?.isNotEmpty ?? false)
            p.subAdministrativeArea!,
          if (p.administrativeArea?.isNotEmpty ?? false) p.administrativeArea!,
        ];
        if (parts.isNotEmpty) {
          setState(() => _resolvedAddress = parts.join(', '));
        }
      }
    } catch (_) {}
  }

  Future<void> _launchNavigation() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final latLng = LatLng(widget.latitude, widget.longitude);
    final displayAddress = _resolvedAddress ??
        'Tọa độ ${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)}';

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: AppDimens.iconSizeBase,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimens.spacingSm),
                  Text(
                    'Vị trí sự cố',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _launchNavigation,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chỉ đường',
                        style: AppTextStyles.buttonText.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSm),

          // Bản đồ phụ gọn (Chiều cao chỉ 105px)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            child: SizedBox(
              height: 105,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: latLng,
                      initialZoom: 15.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: AppConfig.mapTileUrl,
                        userAgentPackageName: 'com.example.urban_issue_app',
                        tileBuilder: AppMapTileStyle.lightMuted,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: latLng,
                            width: 32,
                            height: 32,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(onTap: _launchNavigation),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.spacingSm),

          Text(
            displayAddress,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
