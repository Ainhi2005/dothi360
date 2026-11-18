import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/utility_models.dart';

final floodPointsProvider = FutureProvider<List<FloodPointModel>>((ref) async {
  final res = await DioClient().dio.get('/utilities/flood-points');
  final list = res.data['data'] as List? ?? [];
  return list.map((item) => FloodPointModel.fromJson(item as Map<String, dynamic>)).toList();
});

final weatherAqiProvider = FutureProvider<WeatherAqiModel>((ref) async {
  final res = await DioClient().dio.get('/utilities/weather-aqi');
  return WeatherAqiModel.fromJson(res.data['data'] as Map<String, dynamic>);
});

final departmentsProvider = FutureProvider<List<DepartmentItemModel>>((ref) async {
  final res = await DioClient().dio.get('/utilities/departments');
  final list = res.data['data'] as List? ?? [];
  return list.map((item) => DepartmentItemModel.fromJson(item as Map<String, dynamic>)).toList();
});

final utilitiesSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await DioClient().dio.get('/utilities/summary');
  return Map<String, dynamic>.from(res.data['data'] ?? const {});
});
