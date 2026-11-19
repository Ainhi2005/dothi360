import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_environment.dart';
import '../utils/token_storage.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;
  Future<String?>? _refreshing;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    AppConfig.validate();
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage().getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 428 &&
              e.response?.data is Map &&
              e.response?.data['code'] == 'PASSWORD_CHANGE_REQUIRED') {
            await TokenStorage().savePasswordChangeRequired(true);
          }
          final alreadyRetried = e.requestOptions.extra['retried'] == true;
          final isAuth = e.requestOptions.path.contains('/auth/login') ||
              e.requestOptions.path.contains('/auth/refresh');
          if (e.response?.statusCode == 401 && alreadyRetried && !isAuth) {
            await TokenStorage().deleteToken();
          }
          if (e.response?.statusCode == 401 && !alreadyRetried && !isAuth) {
            final storage = TokenStorage();
            final currentToken = await storage.getToken();
            final failedAuthorization =
                e.requestOptions.headers['Authorization']?.toString();

            // Một request khác có thể đã refresh trong lúc request này đang bay.
            // Khi đó dùng token mới trong storage, không rotation refresh token lần nữa.
            final token = currentToken != null &&
                    failedAuthorization != 'Bearer $currentToken'
                ? currentToken
                : await _refreshAccessToken();
            if (token != null) {
              try {
                final response = await dio.fetch<dynamic>(
                  e.requestOptions.copyWith(
                    headers: {
                      ...e.requestOptions.headers,
                      'Authorization': 'Bearer $token',
                    },
                    extra: {
                      ...e.requestOptions.extra,
                      'retried': true,
                    },
                  ),
                );
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
  Future<String?> _refreshAccessToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _doRefresh() async {
    final refresh = await TokenStorage().getRefreshToken();
    if (refresh == null) return null;
    try {
      final clean = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      final response =
          await clean.post('/auth/refresh', data: {'refresh_token': refresh});
      final access = response.data['data']['access_token']?.toString();
      final rotated = response.data['data']['refresh_token']?.toString();
      if (access != null) await TokenStorage().saveToken(access);
      if (rotated != null) await TokenStorage().saveRefreshToken(rotated);
      if (access != null) {
        await TokenStorage().savePasswordChangeRequired(
            response.data['data']['user']?['must_change_password'] == true);
      }
      return access;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await TokenStorage().deleteToken();
      }
      return null;
    }
  }
}
