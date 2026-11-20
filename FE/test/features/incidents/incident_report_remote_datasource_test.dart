import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_issue_app/features/incidents/data/datasources/incident_report_remote_datasource.dart';

class ReportAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Map<String, dynamic> body = {'success': true, 'data': <String, dynamic>{}};

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (requestStream != null) await requestStream.drain<void>();
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late ReportAdapter adapter;
  late IncidentReportRemoteDataSource remote;
  setUp(() {
    adapter = ReportAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
      ..httpClientAdapter = adapter;
    remote = IncidentReportRemoteDataSource(dio: dio);
  });
  tearDown(() => dio.close(force: true));

  test('phân tích giữ mô tả và metadata; tạo/gộp giữ nguyên biên nhận',
      () async {
    final media = [
      {'url': 'https://example.test/a.jpg', 'storage_key': 'a'}
    ];
    adapter.body = {
      'data': {'suggested_severity': 3}
    };
    expect(
        (await remote.analyze('Cột đèn nghiêng', media))['suggested_severity'],
        3);
    expect(adapter.requests.last.path, '/incidents/analyze');
    expect(adapter.requests.last.data,
        {'description': 'Cột đèn nghiêng', 'media_urls': media});
    final payload = {
      'description': 'Cột đèn nghiêng',
      'longitude': 105.8,
      'latitude': 21.0,
      'media_urls': media
    };
    adapter.body = {
      'success': true,
      'data': {
        'incident_id': 'existing',
        'is_new_incident': false,
        'media_attached': false
      }
    };
    final result = await remote.submit(payload);
    expect(adapter.requests.last.path, '/incidents');
    expect(adapter.requests.last.data, payload);
    expect(result['media_attached'], false);
    expect(result['incident_id'], 'existing');
  });

  test('lỗi HTTP hoặc nghiệp vụ không được coi là gửi thành công', () async {
    adapter.body = {'success': false, 'message': 'Trạng thái đã thay đổi'};
    await expectLater(remote.submit({}), throwsA('Trạng thái đã thay đổi'));
    adapter.status = 503;
    await expectLater(remote.analyze('test', []), throwsA(isA<DioException>()));
  });

  test('upload multipart và dọn file giữ đúng storage key/type', () async {
    final directory = await Directory.systemTemp.createTemp('report-api-test-');
    try {
      final file =
          await File('${directory.path}/scene.jpg').writeAsBytes([1, 2, 3]);
      adapter.body = {
        'data': {
          'url': 'https://example.test/a.jpg',
          'storage_key': 'reports/a',
          'type': 'image/jpeg'
        }
      };
      final uploaded = await remote.upload(file);
      expect(adapter.requests.last.path, '/media/upload');
      expect(adapter.requests.last.data, isA<FormData>());
      await remote.deleteUpload(uploaded);
      expect(adapter.requests.last.method, 'DELETE');
      expect(adapter.requests.last.data,
          {'storage_key': 'reports/a', 'type': 'image/jpeg'});
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
