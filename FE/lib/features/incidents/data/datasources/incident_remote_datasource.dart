import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class IncidentRemoteDataSource {
  IncidentRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  Future<Map<String, dynamic>> submitIncident(
      Map<String, dynamic> requestData) async {
    try {
      final response = await _dio.post('/incidents', data: requestData);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['message'] ?? 'Lỗi kết nối máy chủ');
      }
      throw Exception('Đã xảy ra lỗi không xác định');
    }
  }
}
