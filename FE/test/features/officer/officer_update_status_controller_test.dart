import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_issue_app/features/officer/data/datasources/officer_remote_datasource.dart';
import 'package:urban_issue_app/features/officer/data/models/officer_assignment_model.dart';
import 'package:urban_issue_app/features/officer/presentation/controllers/officer_update_status_controller.dart';

class FakeOfficerSource extends OfficerRemoteDataSource {
  int submissions = 0;
  int cleared = 0;
  Map<String, dynamic>? queued;
  String? sentStatus;
  bool offline = false;
  bool missingChecklist = false;
  Completer<Map<String, dynamic>?>? draft;
  @override
  Future<Map<String, dynamic>?> readDraft(String incidentId) async =>
      draft == null ? null : await draft!.future;
  @override
  Future<List<Map<String, dynamic>>> getChecklist(String incidentId) async =>
      missingChecklist
          ? [
              {'is_required': true, 'completed': false}
            ]
          : [];
  @override
  Future<String> uploadEvidence(String path) async =>
      'https://example.test/proof.jpg';
  @override
  Future<void> clearDraft(String incidentId) async {
    cleared++;
  }

  @override
  Future<void> queueProgress(Map<String, dynamic> data) async {
    queued = data;
  }

  @override
  Future<void> addProgress(
      {required String incidentId,
      required String note,
      required int progressPercent,
      required bool isPublic,
      DateTime? estimatedCompletionAt,
      String? blocker,
      List<String> mediaUrls = const []}) async {
    submissions++;
    if (offline) {
      throw DioException(
          requestOptions: RequestOptions(path: '/progress'),
          type: DioExceptionType.connectionError);
    }
  }

  @override
  Future<void> updateStatus(
      {required String incidentId,
      required String status,
      required String note,
      List<String> mediaUrls = const []}) async {
    submissions++;
    sentStatus = status;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeOfficerSource source;
  late OfficerUpdateStatusController controller;
  late List<String> messages;
  late int saved;
  late int navigated;
  late bool confirm;
  setUp(() {
    source = FakeOfficerSource();
    messages = [];
    saved = 0;
    navigated = 0;
    confirm = true;
    controller = OfficerUpdateStatusController(
      assignment: OfficerAssignmentModel(
          id: 'a',
          incidentId: 'i',
          description: 'Test',
          status: 'IN_PROGRESS',
          incidentTypeName: 'Test',
          departmentName: 'Test',
          assignedAt: DateTime(2026, 11, 20)),
      source: source,
      onMessage: (text, _) => messages.add(text),
      confirmChecklist: (_) async => confirm,
      onSaved: () => saved++,
      onNavigate: () => navigated++,
    );
  });
  tearDown(() {
    if (controller.mounted) controller.dispose();
  });

  test('ghi chú trống và nghiệm thu thiếu minh chứng không gửi API', () async {
    await controller.submit();
    expect(source.submissions, 0);
    controller.noteController.text = 'Đã xử lý';
    controller.inProgressAction = 'verification';
    await controller.submit();
    expect(source.submissions, 0);
    expect(messages.last, contains('minh chứng'));
  });

  test('cập nhật tiến độ không đổi trạng thái; thành công dọn nháp và làm mới',
      () async {
    controller.noteController.text = 'Đã kiểm tra hiện trường';
    await controller.submit();
    expect(source.submissions, 1);
    expect(source.sentStatus, isNull);
    expect(source.cleared, 1);
    expect(saved, 1);
    expect(navigated, 1);
    expect(controller.loading, false);
  });

  test(
      'hủy cảnh báo checklist không gửi; xác nhận gửi đúng trạng thái chờ nghiệm thu',
      () async {
    controller.noteController.text = 'Đã xử lý hiện trường';
    controller.inProgressAction = 'verification';
    controller.evidence.add(File('proof.jpg'));
    source.missingChecklist = true;
    confirm = false;
    await controller.submit();
    expect(source.submissions, 0);
    confirm = true;
    await controller.submit();
    expect(source.sentStatus, 'PENDING_VERIFICATION');
    expect(saved, 1);
  });

  test('nhấn gửi liên tiếp chỉ thực hiện một lần khi đang xử lý', () async {
    controller.noteController.text = 'Đã kiểm tra hiện trường';
    await Future.wait([controller.submit(), controller.submit()]);
    expect(source.submissions, 1);
    expect(saved, 1);
  });

  test('mất mạng lưu hàng đợi, không thông báo đã gửi thành công', () async {
    source.offline = true;
    controller.noteController.text = 'Đang xử lý hiện trường';
    await controller.submit();
    expect(source.queued?['incident_id'], 'i');
    expect(source.queued?['action'], 'progress');
    expect(source.cleared, 0);
    expect(saved, 0);
    expect(messages.last, contains('hàng đợi'));
  });

  test('bản nháp trả về sau dispose không cập nhật controller', () async {
    source.draft = Completer<Map<String, dynamic>?>();
    final pending = controller.loadDraft();
    controller.dispose();
    source.draft!.complete({'note': 'Nháp cũ'});
    await pending;
    expect(messages, isEmpty);
  });
}
