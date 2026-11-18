class FloodPointModel {
  const FloodPointModel({
    required this.id,
    required this.title,
    required this.coordinates,
    required this.severityLevel,
    required this.estimatedDepthCm,
    required this.depthDescription,
    required this.status,
    required this.statusLabel,
    required this.reportCount,
    this.coverUrl,
    required this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String title;
  final List<double> coordinates;
  final int severityLevel;
  final int estimatedDepthCm;
  final String depthDescription;
  final String status;
  final String statusLabel;
  final int reportCount;
  final String? coverUrl;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  factory FloodPointModel.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'] as List? ?? [105.8542, 21.0285];
    final coords = rawCoords.map((e) => (e as num).toDouble()).toList();
    return FloodPointModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Điểm ngập úng',
      coordinates: coords,
      severityLevel: json['severity_level'] as int? ?? 3,
      estimatedDepthCm: json['estimated_depth_cm'] as int? ?? 25,
      depthDescription: json['depth_description']?.toString() ?? 'Ngập nhẹ',
      status: json['status']?.toString() ?? 'ACTIVE',
      statusLabel: json['status_label']?.toString() ?? 'Đang ngập',
      reportCount: json['report_count'] as int? ?? 1,
      coverUrl: json['cover_url']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      resolvedAt: DateTime.tryParse(json['resolved_at']?.toString() ?? ''),
    );
  }
}

class WeatherAqiModel {
  const WeatherAqiModel({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeedKmh,
    required this.precipitationMm,
    required this.weatherDescription,
    required this.weatherIcon,
    required this.aqi,
    required this.aqiStatus,
    required this.aqiColorHex,
    required this.pm25,
    required this.pm10,
    required this.aqiDescription,
    required this.healthAdvice,
    required this.floodRiskLevel,
    required this.floodRiskNote,
  });

  final int temperature;
  final int apparentTemperature;
  final int humidity;
  final int windSpeedKmh;
  final double precipitationMm;
  final String weatherDescription;
  final String weatherIcon;
  final int aqi;
  final String aqiStatus;
  final String aqiColorHex;
  final double pm25;
  final double pm10;
  final String aqiDescription;
  final String healthAdvice;
  final String floodRiskLevel;
  final String floodRiskNote;

  factory WeatherAqiModel.fromJson(Map<String, dynamic> json) {
    final w = json['weather'] as Map<String, dynamic>? ?? {};
    final a = json['air_quality'] as Map<String, dynamic>? ?? {};
    final f = json['flood_risk'] as Map<String, dynamic>? ?? {};

    return WeatherAqiModel(
      temperature: (w['temperature'] as num?)?.toInt() ?? 29,
      apparentTemperature: (w['apparent_temperature'] as num?)?.toInt() ?? 30,
      humidity: (w['humidity'] as num?)?.toInt() ?? 70,
      windSpeedKmh: (w['wind_speed_kmh'] as num?)?.toInt() ?? 10,
      precipitationMm: (w['precipitation_mm'] as num?)?.toDouble() ?? 0.0,
      weatherDescription: w['description']?.toString() ?? 'Trời nắng mây rải rác',
      weatherIcon: w['icon']?.toString() ?? 'sunny',
      aqi: (a['aqi'] as num?)?.toInt() ?? 55,
      aqiStatus: a['status']?.toString() ?? 'Trung bình',
      aqiColorHex: a['color']?.toString() ?? '#EAB308',
      pm25: (a['pm2_5'] as num?)?.toDouble() ?? 22.0,
      pm10: (a['pm10'] as num?)?.toDouble() ?? 38.0,
      aqiDescription: a['description']?.toString() ?? 'Chất lượng không khí bình thường.',
      healthAdvice: a['health_advice']?.toString() ?? 'Người nhạy cảm nên chú ý khi ra ngoài.',
      floodRiskLevel: f['level']?.toString() ?? 'THẤP',
      floodRiskNote: f['note']?.toString() ?? 'Hệ thống thoát nước hoạt động bình thường.',
    );
  }
}

class DepartmentItemModel {
  const DepartmentItemModel({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.phone,
    this.email,
    this.distanceKm,
    required this.managedIncidentTypes,
  });

  final String id;
  final String code;
  final String name;
  final String address;
  final String phone;
  final String? email;
  final double? distanceKm;
  final List<String> managedIncidentTypes;

  factory DepartmentItemModel.fromJson(Map<String, dynamic> json) {
    final rawTypes = json['managed_incident_types'] as List? ?? [];
    return DepartmentItemModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Đơn vị đô thị',
      address: json['address']?.toString() ?? 'Đang cập nhật địa chỉ',
      phone: json['phone']?.toString() ?? '1022',
      email: json['email']?.toString(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      managedIncidentTypes: rawTypes.map((e) => e.toString()).toList(),
    );
  }
}
