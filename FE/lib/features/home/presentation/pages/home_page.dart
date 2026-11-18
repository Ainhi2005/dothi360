import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/home_content.dart';
import '../widgets/home_load_error.dart';

final homeOverviewProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final results = await Future.wait([
    DioClient().dio.get('/auth/me'),
    DioClient().dio.get('/incidents/me/reports'),
    DioClient().dio.get('/notifications', queryParameters: {'limit': 20}),
    DioClient().dio.get('/incidents', queryParameters: {'limit': 50}),
  ]);
  final notifications = List<Map<String, dynamic>>.from(
    results[2].data['data'] ?? const [],
  );
  Map<String, dynamic>? areaAlert;
  for (final notification in notifications) {
    if (const ['ALERT', 'EMERGENCY', 'AREA_WARNING']
        .contains(notification['type'])) {
      areaAlert = notification;
      break;
    }
  }
  return {
    'user': results[0].data['data'],
    'mine': results[1].data['data'],
    'unread': results[2].data['unread'] ?? 0,
    'area_alert': areaAlert,
    'notifications': notifications,
    'community': results[3].data['data'],
  };
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(homeOverviewProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: overview.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
        error: (_, __) => HomeLoadError(
          onRetry: () => ref.invalidate(homeOverviewProvider),
        ),
        data: (data) => HomeContent(
          data: data,
          onRefresh: () => ref.refresh(homeOverviewProvider.future),
        ),
      ),
    );
  }
}
