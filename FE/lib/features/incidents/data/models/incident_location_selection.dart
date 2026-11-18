import 'package:latlong2/latlong.dart';

class IncidentLocationSelection {
  const IncidentLocationSelection({
    required this.point,
    required this.source,
    this.address,
  });

  final LatLng point;
  final String? address;
  final String source;
}
