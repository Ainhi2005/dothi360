import '../../../../core/network/dio_client.dart';
import '../models/emergency_guide_model.dart';

class EmergencyGuideRemoteDataSource {
  Future<List<EmergencyGuideModel>> getAll() async {
    final response = await DioClient().dio.get('/emergency-guides');
    final rawList = response.data['data'] as List<dynamic>? ?? const [];
    return rawList
        .map((item) => EmergencyGuideModel.fromJson(
            Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<EmergencyGuideModel> getOne(String id) async {
    final response = await DioClient().dio.get('/emergency-guides/$id');
    return EmergencyGuideModel.fromJson(
        Map<String, dynamic>.from(response.data['data'] as Map));
  }
}
