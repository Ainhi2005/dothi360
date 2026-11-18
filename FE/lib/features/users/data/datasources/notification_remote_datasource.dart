import '../../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  Future<List<NotificationModel>> list() async {
    final res = await DioClient().dio.get('/notifications');
    final data = res.data['data'];
    if (data is List) {
      return data
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> read(String id) async {
    await DioClient().dio.patch('/notifications/$id/read');
  }

  Future<void> readAll() async {
    await DioClient().dio.patch('/notifications/read-all');
  }

  Future<void> delete(String id) async {
    await DioClient().dio.delete('/notifications/$id');
  }

  Future<void> deleteAll() async {
    await DioClient().dio.delete('/notifications/all');
  }
}
