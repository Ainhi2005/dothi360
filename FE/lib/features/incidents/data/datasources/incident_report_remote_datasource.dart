import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

/// Truy cập API của luồng tạo phản ánh, dùng chung phiên đăng nhập từ DioClient.
class IncidentReportRemoteDataSource {
  IncidentReportRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;
  final Dio _dio;

  Future<List<Map<String, dynamic>>> loadIncidentTypes() async {
    final response = await _dio.get('/incident-types');
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<Map<String, dynamic>> upload(File file,
      {ProgressCallback? onSendProgress}) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path,
          filename: file.path.split(Platform.pathSeparator).last),
    });
    final response = await _dio.post('/media/upload',
        data: form, onSendProgress: onSendProgress);
    return Map<String, dynamic>.from(response.data['data']);
  }

  Future<Map<String, dynamic>> analyze(
      String description, List<Map<String, dynamic>> media) async {
    final response = await _dio.post('/incidents/analyze', data: {
      'description': description,
      'media_urls': media,
    });
    return Map<String, dynamic>.from(response.data['data']);
  }

  Future<Map<String, dynamic>> submit(Map<String, dynamic> data) async {
    final response = await _dio.post('/incidents', data: data);
    if (response.data['success'] != true) {
      throw response.data['message'] ?? 'Lỗi không xác định';
    }
    return Map<String, dynamic>.from(response.data['data']);
  }

  Future<void> deleteUpload(Map<String, dynamic> media) async {
    await _dio.delete('/media/upload', data: {
      'storage_key': media['storage_key'],
      'type': media['type'],
    });
  }
}
