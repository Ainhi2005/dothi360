import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'map_incident_marker.dart';

/// Cụm marker sự cố đô thị trên bản đồ số
class IncidentMarkerCluster extends StatelessWidget {
  const IncidentMarkerCluster({
    super.key,
    required this.items,
    required this.onIncidentTap,
  });

  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onIncidentTap;

  @override
  Widget build(BuildContext context) {
    final markers = items
        .map((item) {
          final coordinates = (item['location']?['coordinates'] as List?) ?? [];
          if (coordinates.length < 2) return null;
          final lat = (coordinates[1] as num).toDouble();
          final lng = (coordinates[0] as num).toDouble();
          final status = item['status']?.toString() ?? 'PENDING_ASSIGNMENT';

          return Marker(
            point: LatLng(lat, lng),
            width: AppDimens.mapMarkerSize,
            height: AppDimens.mapMarkerSize,
            child: MapIncidentMarker(
              status: status,
              onTap: () => onIncidentTap(item),
            ),
          );
        })
        .whereType<Marker>()
        .toList();

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        maxClusterRadius: 48,
        size: const Size(AppDimens.mapClusterSize, AppDimens.mapClusterSize),
        markers: markers,
        builder: (context, clusteredMarkers) => Container(
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.24),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${clusteredMarkers.length}',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
