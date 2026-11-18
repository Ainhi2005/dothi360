import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/providers/utility_providers.dart';
import '../widgets/aqi_detail_card.dart';
import '../widgets/weather_metrics_grid.dart';

class WeatherAqiPage extends ConsumerWidget {
  const WeatherAqiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherAqiProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Không khí & Thời tiết',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.homeNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: weatherAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.error),
              const SizedBox(height: AppDimens.spacingSm),
              Text('Không thể tải thông tin thời tiết', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppDimens.spacingMd),
              FilledButton(
                onPressed: () => ref.invalidate(weatherAqiProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.refresh(weatherAqiProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            children: [
              AqiDetailCard(data: data),
              const SizedBox(height: AppDimens.spacingLg),
              WeatherMetricsGrid(data: data),
              const SizedBox(height: AppDimens.spacingLg),
              _buildFloodRiskCard(data),
              const SizedBox(height: AppDimens.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloodRiskCard(dynamic data) {
    final isHigh = data.floodRiskLevel == 'CAO';
    final isMedium = data.floodRiskLevel == 'TRUNG BÌNH';

    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: isHigh
            ? AppColors.errorLight
            : isMedium
                ? AppColors.warningLight
                : AppColors.successLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: isHigh
              ? AppColors.error
              : isMedium
                  ? AppColors.warning
                  : AppColors.success,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHigh ? Icons.warning_amber_rounded : Icons.shield_outlined,
            color: isHigh
                ? AppColors.error
                : isMedium
                    ? AppColors.warning
                    : AppColors.success,
            size: AppDimens.iconSizeMd,
          ),
          const SizedBox(width: AppDimens.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cảnh báo nguy cơ ngập úng: CẤP ${data.floodRiskLevel}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isHigh
                        ? AppColors.error
                        : isMedium
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.floodRiskNote,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.homeNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
