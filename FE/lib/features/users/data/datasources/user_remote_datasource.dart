import '../../../../core/network/dio_client.dart';
import '../models/user_profile_model.dart';

class UserRemoteDataSource {
  Future<UserProfileModel> getProfile() async {
    final response = await DioClient().dio.get('/auth/me');
    return UserProfileModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<UserProfileModel> updateProfile(
      {required String fullName, required String phone}) async {
    final response = await DioClient().dio.patch('/users/me', data: {
      'full_name': fullName,
      'phone': phone,
    });
    return UserProfileModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) async {
    await DioClient().dio.patch('/auth/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}
