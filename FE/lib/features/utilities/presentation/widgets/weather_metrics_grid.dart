import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/utility_models.dart';

class WeatherMetricsGrid extends StatelessWidget {
  const WeatherMetricsGrid({super.key, required this.data});

  final WeatherAqiModel data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingXs),
          child: Text(
            'Thông số thời tiết đô thị',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.homeNavy,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.spacingSm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppDimens.spacingMd,
          crossAxisSpacing: AppDimens.spacingMd,
          childAspectRatio: 1.6,
          children: [
            _buildMetric(
              'Nhiệt độ cảm nhận',
              '${data.apparentTemperature}°C',
              Icons.thermostat_outlined,
              AppColors.homeOrange,
            ),
            _buildMetric(
              'Độ ẩm không khí',
              '${data.humidity}%',
              Icons.water_drop_outlined,
              AppColors.info,
            ),
            _buildMetric(
              'Tốc độ gió',
              '${data.windSpeedKmh} km/h',
              Icons.air,
              AppColors.homeGreen,
            ),
            _buildMetric(
              'Lượng mưa hôm nay',
              '${data.precipitationMm} mm',
              Icons.umbrella_outlined,
              AppColors.categoryFlood,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: AppDimens.iconSizeSm),
              const SizedBox(width: AppDimens.spacingXs),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSm),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.homeNavy,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
