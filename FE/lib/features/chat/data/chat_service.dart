import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import 'models/chat_suggestion.dart';

class ChatService {
  static const maxMessageLength = 2000;
  static const historyLimit = 10;
  ChatService({Dio? dio}) : _dio = dio ?? DioClient().dio;
  final Dio _dio;
  Future<List<ChatSuggestion>> loadSuggestions() async {
    final response = await _dio.get('/chat/suggestions');
    return (response.data['data'] as List)
        .map((item) =>
            ChatSuggestion.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<String> send(String message,
      {List<Map<String, String>> history = const [],
      String? suggestionId}) async {
    final response = await _dio.post('/chat',
        data: {
          'message': message,
          'history': history,
          if (suggestionId != null) 'suggestion_id': suggestionId
        },
        options: Options(receiveTimeout: const Duration(seconds: 45)));
    return response.data['data']?['reply']?.toString() ??
        response.data['reply']?.toString() ??
        'Trợ lý chưa thể trả lời lúc này.';
  }
}
