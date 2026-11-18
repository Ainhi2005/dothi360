import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../firebase_options.dart';
import '../network/dio_client.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('📬 Nhận tin thông báo chạy ngầm: ${message.notification?.title}');
}

class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();
  static final ValueNotifier<RemoteMessage?> foregroundNotificationStream =
      ValueNotifier(null);
  FirebaseMessaging? _messaging;

  Future<void> initialize() async {
    try {
      // 1. Khởi tạo Firebase với cấu hình tự động từ firebase_options.dart
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _messaging = FirebaseMessaging.instance;

      // 2. Đăng ký nhận tin chạy ngầm (Background handler)
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Xin quyền thông báo (bắt buộc cho Android 13+ và iOS)
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
          '🔔 Trạng thái cấp quyền thông báo: ${settings.authorizationStatus}');

      // 4. Lấy mã FCM Token của thiết bị và in ra console
      // ignore: deprecated_member_use
      final token = await _messaging!.getToken();
      debugPrint('====================================================');
      debugPrint('🔥 MÃ FCM TOKEN CỦA THIẾT BỊ ĐỂ TEST FIREBASE:');
      debugPrint('$token');
      debugPrint('====================================================');

      if (token != null) {
        await _register(token);
      }

      // 5. Lắng nghe thông báo khi ứng dụng đang mở (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            '📩 Nhận thông báo Foreground: ${message.notification?.title} - ${message.notification?.body}');
        foregroundNotificationStream.value = message;
        _showForegroundBanner(message);
      });

      // 6. Lắng nghe khi người dùng bấm vào thông báo mở app
      FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);

      // 7. Xử lý khi app khởi động từ một thông báo
      final initial = await _messaging!.getInitialMessage();
      if (initial != null) {
        _openMessage(initial);
      }

      // 8. Lắng nghe khi token thay đổi
      // ignore: deprecated_member_use
      _messaging!.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token vừa được làm mới: $newToken');
        _register(newToken);
      });
    } catch (e) {
      debugPrint('⚠️ Không thể khởi tạo Firebase Messaging: $e');
    }
  }

  Future<void> registerCurrentDevice() async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) {
        await _register(token);
      }
    } catch (_) {}
  }

  Future<void> unregisterCurrentDevice() async {
    // ignore: deprecated_member_use
    final token = await _messaging?.getToken();
    if (token == null) return;
    try {
      await DioClient()
          .dio
          .delete('/notifications/devices', data: {'token': token});
    } catch (_) {}
  }

  Future<void> _register(String token) async {
    try {
      await DioClient().dio.post(
        '/notifications/devices',
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
        },
      );
      debugPrint('✅ Đã đăng ký FCM Token thành công lên server Backend.');
    } catch (_) {
      // Khi chưa đăng nhập thì API có thể trả 401, token sẽ được lưu lại sau khi login
    }
  }

  void _openMessage(RemoteMessage message) {
    if (message.data['feedback_id']?.toString().isNotEmpty == true) {
      appRouter.push(AppRoutes.feedbacks);
      return;
    }
    final assignmentId = message.data['assignment_id']?.toString();
    if (message.data['type'] == 'ASSIGNMENT_CREATED' &&
        assignmentId != null &&
        assignmentId.isNotEmpty) {
      appRouter.push(AppRoutes.officerAssignmentPath(assignmentId));
      return;
    }
    final incidentId = message.data['incident_id']?.toString();
    if (incidentId != null && incidentId.isNotEmpty) {
      appRouter.push(AppRoutes.incidentDetailPath(incidentId));
    }
  }

  void _showForegroundBanner(RemoteMessage message) {
    final title = message.notification?.title ?? 'Thông báo mới';
    final body = message.notification?.body ?? '';
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppDimens.spacingMd),
        backgroundColor: AppColors.homeNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.spacingSm),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: AppColors.surface,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimens.spacingMd),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.surface.withValues(alpha: 0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Xem',
          textColor: AppColors.homeYellow,
          onPressed: () => _openMessage(message),
        ),
      ),
    );
  }
}
