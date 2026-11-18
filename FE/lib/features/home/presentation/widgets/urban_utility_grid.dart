import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Khối "Tiện ích đô thị" — Card trắng chứa 2 hàng tiện ích (8 tiện ích phong phú):
/// Hàng 1: Trợ lý AI, Cẩm nang, Danh bạ SOS, Khu vực
/// Hàng 2: Thời tiết, Ngập úng, Đơn vị, Tất cả
class UrbanUtilityGrid extends StatelessWidget {
  const UrbanUtilityGrid({
    super.key,
    required this.onAiAssistant,
    required this.onEmergencyGuide,
    required this.onEmergencyContacts,
    required this.onInterestedArea,
    required this.onWeather,
    required this.onFloodPoints,
    required this.onDepartments,
    required this.onFeedback,
  });

  final VoidCallback onAiAssistant;
  final VoidCallback onEmergencyGuide;
  final VoidCallback onEmergencyContacts;
  final VoidCallback onInterestedArea;
  final VoidCallback onWeather;
  final VoidCallback onFloodPoints;
  final VoidCallback onDepartments;
  final VoidCallback onFeedback;

  @override
  Widget build(BuildContext context) {
    final row1 = [
      _UtilityItem(
        label: 'Trợ lý AI',
        asset: AppAssets.accountAiAssistant,
        fallbackIcon: Icons.auto_awesome_rounded,
        onTap: onAiAssistant,
      ),
      _UtilityItem(
        label: 'Cẩm nang',
        asset: AppAssets.emergencyGuide,
        fallbackIcon: Icons.menu_book_rounded,
        onTap: onEmergencyGuide,
      ),
      _UtilityItem(
        label: 'Danh bạ SOS',
        asset: AppAssets.emergencyContact,
        fallbackIcon: Icons.phone_in_talk_rounded,
        onTap: onEmergencyContacts,
      ),
      _UtilityItem(
        label: 'Khu vực',
        asset: AppAssets.interestedArea,
        fallbackIcon: Icons.location_on_rounded,
        onTap: onInterestedArea,
      ),
    ];

    final row2 = [
      _UtilityItem(
        label: 'Thời tiết',
        asset: AppAssets.weather,
        fallbackIcon: Icons.wb_sunny_rounded,
        onTap: onWeather,
      ),
      _UtilityItem(
        label: 'Ngập úng',
        asset: AppAssets.flood,
        fallbackIcon: Icons.water_drop_rounded,
        onTap: onFloodPoints,
      ),
      _UtilityItem(
        label: 'Đơn vị',
        asset: AppAssets.department,
        fallbackIcon: Icons.apartment_rounded,
        onTap: onDepartments,
      ),
      _UtilityItem(
        label: 'Góp ý',
        asset: AppAssets.feedback,
        fallbackIcon: Icons.lightbulb_outline_rounded,
        onTap: onFeedback,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.spacingBase,
        AppDimens.spacingSm,
        AppDimens.spacingBase,
        AppDimens.spacingBase,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tiêu đề: Tiện ích đô thị
          Text(
            'Tiện ích đô thị',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppDimens.spacingSm),
          // Container thẻ trắng bo góc chứa 2 hàng tiện ích
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSubtle,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: row1
                      .map(
                        (item) => Expanded(
                          child: _UtilityTile(item: item),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: row2
                      .map(
                        (item) => Expanded(
                          child: _UtilityTile(item: item),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityItem {
  const _UtilityItem({
    required this.label,
    required this.asset,
    required this.fallbackIcon,
    required this.onTap,
  });

  final String label;
  final String asset;
  final IconData fallbackIcon;
  final VoidCallback onTap;
}

class _UtilityTile extends StatelessWidget {
  const _UtilityTile({required this.item});

  final _UtilityItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.spacing2Xs,
          horizontal: AppDimens.spacing2Xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Image.asset(
                item.asset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  item.fallbackIcon,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
