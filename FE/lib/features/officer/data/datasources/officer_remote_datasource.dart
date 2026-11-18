import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/officer_assignment_model.dart';
import '../models/officer_dashboard_model.dart';
import '../services/officer_offline_store.dart';

class OfficerRemoteDataSource {
  final Dio _dio = DioClient().dio;
  final OfficerOfflineStore _offline = OfficerOfflineStore();

  Future<OfficerDashboardModel> getDashboard() async {
    final response = await _dio.get('/assignments/officer-dashboard');
    return OfficerDashboardModel.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await _dio.get('/notifications', queryParameters: {
      'page': 1,
      'limit': 1,
    });
    return int.tryParse('${response.data['unread'] ?? 0}') ?? 0;
  }

  Future<List<OfficerAssignmentModel>> getAssignments(String scope) async {
    List<dynamic> data;
    try {
      final response = await _dio
          .get('/assignments/department', queryParameters: {'scope': scope});
      data = response.data['data'] as List<dynamic>? ?? const [];
      await _offline.cacheAssignments(scope, data);
    } on DioException {
      data = await _offline.readAssignments(scope);
      if (data.isEmpty) rethrow;
    }
    return data
        .map((item) =>
            OfficerAssignmentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> pendingSyncCount() async => (await _offline.readQueue()).length;

  Future<void> queueProgress(Map<String, dynamic> data) =>
      _offline.enqueue(data);

  Future<void> saveDraft(String incidentId, Map<String, dynamic> draft) =>
      _offline.saveDraft(incidentId, draft);

  Future<Map<String, dynamic>?> readDraft(String incidentId) =>
      _offline.readDraft(incidentId);

  Future<void> clearDraft(String incidentId) => _offline.clearDraft(incidentId);

  Future<int> syncPending() async {
    final queue = await _offline.readQueue();
    final remaining = <Map<String, dynamic>>[];
    for (final item in queue) {
      try {
        final urls = <String>[];
        for (final path in List<String>.from(item['local_paths'] ?? const [])) {
          if (await File(path).exists()) urls.add(await uploadEvidence(path));
        }
        if (item['action'] == 'progress') {
          await addProgress(
              incidentId: item['incident_id'].toString(),
              note: item['note'].toString(),
              progressPercent: item['progress_percent'] as int,
              isPublic: item['is_public'] == true,
              blocker: item['blocker']?.toString(),
              estimatedCompletionAt: DateTime.tryParse(
                  item['estimated_completion_at']?.toString() ?? ''),
              mediaUrls: urls);
        } else {
          await updateStatus(
              incidentId: item['incident_id'].toString(),
              status: item['status'].toString(),
              note: item['note'].toString(),
              mediaUrls: urls);
        }
      } on DioException catch (e) {
        if (e.response != null &&
            e.response!.statusCode != null &&
            e.response!.statusCode! >= 400 &&
            e.response!.statusCode! < 500 &&
            e.response!.statusCode != 408) {
          // Drop non-retryable 4xx client errors
        } else {
          remaining.add(item);
        }
      }
    }
    await _offline.writeQueue(remaining);
    return remaining.length;
  }

  Future<void> accept(String assignmentId) async {
    await _dio.post('/assignments/$assignmentId/accept');
  }

  Future<void> reject({
    required String assignmentId,
    required String reasonCode,
    required String reason,
  }) async {
    await _dio.post('/assignments/$assignmentId/reject', data: {
      'reason_code': reasonCode,
      'reason': reason,
    });
  }

  Future<OfficerAssignmentModel> getAssignment(String assignmentId) async {
    final response = await _dio.get('/assignments/$assignmentId');
    return OfficerAssignmentModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> updateStatus({
    required String incidentId,
    required String status,
    required String note,
    List<String> mediaUrls = const [],
  }) async {
    await _dio.patch('/incidents/$incidentId/status', data: {
      'status': status,
      'note': note,
      'media_urls': mediaUrls,
    });
  }

  Future<void> addProgress({
    required String incidentId,
    required String note,
    required int progressPercent,
    required bool isPublic,
    DateTime? estimatedCompletionAt,
    String? blocker,
    List<String> mediaUrls = const [],
  }) async {
    await _dio.post('/incidents/$incidentId/progress', data: {
      'note': note,
      'media_urls': mediaUrls,
      'progress_percent': progressPercent,
      'estimated_completion_at':
          estimatedCompletionAt?.toUtc().toIso8601String(),
      'blocker': blocker?.trim().isEmpty == true ? null : blocker?.trim(),
      'visibility': isPublic ? 'PUBLIC' : 'INTERNAL',
    });
  }

  Future<String> uploadEvidence(String path) async {
    final response = await _dio.post(
      '/media/upload',
      data: FormData.fromMap({'file': await MultipartFile.fromFile(path)}),
    );
    return response.data['data']['url'].toString();
  }

  Future<List<Map<String, dynamic>>> getChecklist(String incidentId) async {
    final response =
        await _dio.get('/officer-operations/incidents/$incidentId/checklist');
    return List<Map<String, dynamic>>.from(response.data['data'] ?? const []);
  }

  Future<void> saveChecklist(
      String incidentId, List<Map<String, dynamic>> items) async {
    await _dio.put('/officer-operations/incidents/$incidentId/checklist',
        data: {'items': items});
  }

  Future<Map<String, dynamic>> getPerformance() async {
    final response = await _dio.get('/officer-operations/performance/me');
    return Map<String, dynamic>.from(response.data['data']);
  }
}
