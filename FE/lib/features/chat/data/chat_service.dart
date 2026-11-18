import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class ChatService {
  ChatService({Dio? dio}) : _dio = dio ?? DioClient().dio;
  final Dio _dio;

  Future<String> send(String message) async {
    final response = await _dio.post('/chat', data: {'message': message});
    return response.data['data']?['reply']?.toString() ??
        response.data['reply']?.toString() ??
        'Trợ lý chưa thể trả lời lúc này.';
  }
}
