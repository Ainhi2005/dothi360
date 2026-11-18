import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/utility_models.dart';

class AqiDetailCard extends StatelessWidget {
  const AqiDetailCard({super.key, required this.data});

  final WeatherAqiModel data;

  @override
  Widget build(BuildContext context) {
    Color aqiColor = AppColors.homeGreen;
    if (data.aqi > 150) {
      aqiColor = AppColors.error;
    } else if (data.aqi > 100) {
      aqiColor = AppColors.homeOrange;
    } else if (data.aqi > 50) {
      aqiColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.air, color: AppColors.homeNavy),
              const SizedBox(width: AppDimens.spacingSm),
              Text(
                'Chỉ số chất lượng không khí',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.homeNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingLg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${data.aqi}',
                style: AppTextStyles.headingLarge.copyWith(
                  fontSize: 54,
                  fontWeight: FontWeight.w800,
                  color: aqiColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: AppDimens.spacingSm),
              Text(
                'AQI',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingMd,
                  vertical: AppDimens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: aqiColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(color: aqiColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  data.aqiStatus,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: aqiColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingMd),
          Text(
            data.aqiDescription,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),
          const Divider(color: AppColors.divider),
          const SizedBox(height: AppDimens.spacingSm),
          Row(
            children: [
              _buildPollutant('PM 2.5', '${data.pm25} µg/m³'),
              _buildPollutant('PM 10', '${data.pm10} µg/m³'),
            ],
          ),
          const SizedBox(height: AppDimens.spacingMd),
          Container(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.info,
                  size: AppDimens.iconSizeMd,
                ),
                const SizedBox(width: AppDimens.spacingSm),
                Expanded(
                  child: Text(
                    data.healthAdvice,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.info,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollutant(String name, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.homeNavy,
            ),
          ),
        ],
      ),
    );
  }
}
