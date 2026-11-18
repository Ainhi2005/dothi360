import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactsRemoteDataSource {
  final Dio _dio = DioClient().dio;

  Future<List<EmergencyContactModel>> getContacts({
    String? category,
    String? query,
  }) async {
    final response = await _dio.get(
      '/emergency-contacts',
      queryParameters: {
        if (category != null && category != 'ALL') 'category': category,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );

    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => EmergencyContactModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
