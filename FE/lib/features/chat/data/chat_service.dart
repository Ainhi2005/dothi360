import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class ChatService {
  static const maxMessageLength = 2000;
  static const historyLimit = 10;
  ChatService({Dio? dio}) : _dio = dio ?? DioClient().dio;
  final Dio _dio;

  Future<String> send(String message,
      {List<Map<String, String>> history = const []}) async {
    final response = await _dio.post('/chat',
        data: {'message': message, 'history': history},
        options: Options(receiveTimeout: const Duration(seconds: 45)));
    return response.data['data']?['reply']?.toString() ??
        response.data['reply']?.toString() ??
        'Trợ lý chưa thể trả lời lúc này.';
  }
}
