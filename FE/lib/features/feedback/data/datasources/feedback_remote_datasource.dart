import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/citizen_feedback_model.dart';

class FeedbackRemoteDataSource {
  FeedbackRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  Future<List<CitizenFeedbackModel>> list({
    String? category,
    String? sort = 'newest',
    int page = 1,
    int limit = 30,
  }) async {
    final response = await _dio.get(
      '/feedbacks',
      queryParameters: {
        if (category != null && category != 'ALL') 'category': category,
        if (sort != null) 'sort': sort,
        'page': page,
        'limit': limit,
      },
    );
    final rawList = response.data?['data'];
    if (rawList is List) {
      return rawList
          .map((e) => CitizenFeedbackModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<List<CitizenFeedbackModel>> getMine({int page = 1, int limit = 30}) async {
    final response = await _dio.get(
      '/feedbacks/mine',
      queryParameters: {'page': page, 'limit': limit},
    );
    final rawList = response.data?['data'];
    if (rawList is List) {
      return rawList
          .map((e) => CitizenFeedbackModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<CitizenFeedbackModel> create({
    required String title,
    required String content,
    String? category,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _dio.post(
      '/feedbacks',
      data: {
        'title': title,
        'content': content,
        if (category != null) 'category': category,
        if (locationName != null) 'location_name': locationName,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return CitizenFeedbackModel.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }

  Future<Map<String, dynamic>> toggleUpvote(String id) async {
    final response = await _dio.post('/feedbacks/$id/upvote');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }
}

