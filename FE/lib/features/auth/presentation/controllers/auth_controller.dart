import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/token_storage.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../users/presentation/providers/user_profile_provider.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String? userRole;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.userRole,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSuccess,
    String? userRole,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
      userRole: userRole ?? this.userRole,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(error: 'Vui lòng nhập đầy đủ email và mật khẩu');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final dio = DioClient().dio;
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        final token = response.data['data']['access_token'];
        final refreshToken = response.data['data']['refresh_token'];
        if (token != null) {
          await TokenStorage().saveToken(token);
          if (refreshToken != null) {
            await TokenStorage().saveRefreshToken(refreshToken);
          }
          final role = response.data['data']['user']?['role']?.toString();
          if (role != null) {
            await TokenStorage().saveRole(role);
          }
          await PushNotificationService.instance.registerCurrentDevice();
          ref.invalidate(userProfileProvider);
          state = state.copyWith(
            isLoading: false,
            isSuccess: true,
            userRole: role,
          );
        } else {
          throw 'Không nhận được access_token từ server';
        }
      } else {
        throw response.data['message'] ?? 'Đăng nhập thất bại';
      }
    } catch (e) {
      String errMsg = 'Lỗi hệ thống';
      if (e is DioException) {
        errMsg = e.response?.data['message'] ?? 'Lỗi kết nối mạng';
      } else {
        errMsg = e.toString();
      }
      state = state.copyWith(isLoading: false, error: errMsg);
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);
    try {
      final response = await DioClient().dio.post('/auth/register', data: {
        'full_name': fullName,
        'email': email,
        'phone': phone.isEmpty ? null : phone,
        'password': password,
      });
      if (response.data['success'] != true) {
        throw response.data['message'] ?? 'Đăng ký thất bại';
      }
      state = AuthState();
      return true;
    } catch (error) {
      final message = error is DioException
          ? error.response?.data['message']?.toString() ??
              'Không thể kết nối máy chủ'
          : error.toString();
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);
    try {
      await PushNotificationService.instance.unregisterCurrentDevice();
      final refreshToken = await TokenStorage().getRefreshToken();
      if (refreshToken != null) {
        await DioClient()
            .dio
            .post('/auth/logout', data: {'refresh_token': refreshToken});
      }
    } catch (_) {
      // Vẫn xóa phiên cục bộ khi server không khả dụng.
    } finally {
      await TokenStorage().deleteToken();
      ref.invalidate(userProfileProvider);
      state = AuthState();
    }
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  () => AuthController(),
);
