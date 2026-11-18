import '../../../../core/network/dio_client.dart';

class IncidentLocationRemoteDataSource {
  final _dio = DioClient().dio;

  Future<List<Map<String, dynamic>>> search(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    final response = await _dio.get(
      '/interested-areas/search/places',
      queryParameters: {'q': query, 'lat': latitude, 'lng': longitude},
    );
    return List<Map<String, dynamic>>.from(response.data['data'] ?? const []);
  }
}
