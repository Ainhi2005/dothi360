import '../../../../core/network/dio_client.dart';
import '../models/incident_detail_model.dart';
import '../models/report_history_model.dart';
import '../models/incident_list_item_model.dart';

class IncidentHistoryRemoteDataSource {
  Future<List<IncidentListItemModel>> getIncidents() async {
    final response = await DioClient()
        .dio
        .get('/incidents', queryParameters: {'page': 1, 'limit': 50});
    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) =>
            IncidentListItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReportHistoryModel>> getMyReports() async {
    final response = await DioClient().dio.get('/incidents/me/reports');
    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data
        .map(
            (item) => ReportHistoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<IncidentDetailModel> getIncidentDetail(String id) async {
    final response = await DioClient().dio.get('/incidents/$id');
    return IncidentDetailModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> endorseIncident(String id) async {
    final response = await DioClient().dio.post('/incidents/$id/endorse');
    return response.data['data'] as Map<String, dynamic>;
  }
}

