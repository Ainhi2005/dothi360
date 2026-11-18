import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/routing/app_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/push_notification_service.dart';

import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: UrbanCareApp()));
  unawaited(PushNotificationService.instance.initialize());
}

class UrbanCareApp extends StatelessWidget {
  const UrbanCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Đô Thị 360',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          onPrimary: Colors.white,
          outline: AppColors.border,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
