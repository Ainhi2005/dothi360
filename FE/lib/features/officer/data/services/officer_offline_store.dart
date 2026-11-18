import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class OfficerOfflineStore {
  Future<File> _file(String name) async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/officer_$name.json');
  }

  Future<void> cacheAssignments(String scope, List<dynamic> data) async =>
      (await _file('assignments_$scope')).writeAsString(jsonEncode(data));

  Future<List<dynamic>> readAssignments(String scope) async {
    final file = await _file('assignments_$scope');
    if (!await file.exists()) return const [];
    return jsonDecode(await file.readAsString()) as List<dynamic>;
  }

  Future<List<Map<String, dynamic>>> readQueue() async {
    final file = await _file('sync_queue');
    if (!await file.exists()) return [];
    return List<Map<String, dynamic>>.from(
        jsonDecode(await file.readAsString()));
  }

  Future<void> enqueue(Map<String, dynamic> item) async {
    final queue = await readQueue();
    queue.add(item);
    await (await _file('sync_queue')).writeAsString(jsonEncode(queue));
  }

  Future<void> writeQueue(List<Map<String, dynamic>> queue) async =>
      (await _file('sync_queue')).writeAsString(jsonEncode(queue));

  Future<void> saveDraft(String incidentId, Map<String, dynamic> draft) async {
    final file = await _file('draft_$incidentId');
    await file.writeAsString(jsonEncode(draft));
  }

  Future<Map<String, dynamic>?> readDraft(String incidentId) async {
    final file = await _file('draft_$incidentId');
    if (!await file.exists()) return null;
    try {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDraft(String incidentId) async {
    final file = await _file('draft_$incidentId');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
