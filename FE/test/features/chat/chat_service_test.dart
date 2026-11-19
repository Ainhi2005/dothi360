import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_issue_app/features/chat/data/chat_service.dart';

class ChatAdapter implements HttpClientAdapter {
  ChatAdapter({this.status = 200});
  final int status;
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    return ResponseBody.fromString(
        jsonEncode(status == 200
            ? {
                'success': true,
                'data': {'reply': 'Hồ sơ đang xử lý.'}
              }
            : {'success': false, 'message': 'Trợ lý tạm thời chưa sẵn sàng.'}),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('gửi ngữ cảnh chat và đặt timeout riêng cho AI', () async {
    final adapter = ChatAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
      ..httpClientAdapter = adapter;
    final reply =
        await ChatService(dio: dio).send('Kiểm tra tình trạng', history: [
      {'role': 'user', 'content': 'Phản ánh gần nhất của tôi?'}
    ]);
    expect(reply, 'Hồ sơ đang xử lý.');
    expect(adapter.request?.path, '/chat');
    expect(adapter.request?.data['history'][0]['role'], 'user');
    expect(adapter.request?.receiveTimeout, const Duration(seconds: 45));
    dio.close();
  });
  test('không biến lỗi HTTP của AI thành câu trả lời thành công', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
      ..httpClientAdapter = ChatAdapter(status: 503);
    await expectLater(
        ChatService(dio: dio).send('Xin chào'), throwsA(isA<DioException>()));
    dio.close();
  });
}
