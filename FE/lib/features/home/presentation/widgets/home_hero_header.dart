import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../utilities/data/providers/utility_providers.dart';

/// Header đô thị chuẩn format thiết kế:
/// 1. Hàng trên: Thời tiết (trái) + Chuông thông báo & Avatar (phải)
/// 2. Hàng giữa: Lời chào cá nhân hoá "Xin chào, [Tên] 👋"
/// 3. Hàng dưới: Thanh tìm kiếm thông minh kết hợp nút camera Báo nhanh
class HomeHeroHeader extends ConsumerWidget {
  const HomeHeroHeader({
    super.key,
    required this.name,
    required this.unread,
    required this.onNotifications,
    required this.onWeather,
    this.onSearch,
    this.onQuickReport,
    this.onAvatarTap,
    this.avatarUrl,
  });

  final String name;
  final int unread;
  final VoidCallback onNotifications;
  final VoidCallback onWeather;
  final VoidCallback? onSearch;
  final VoidCallback? onQuickReport;
  final VoidCallback? onAvatarTap;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final weatherAsync = ref.watch(weatherAqiProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF26BC65), // Emerald đậm tinh tế
            Color(0xFF5CE09B), // Mint tươi sáng
            Color(0xFFDCF7E9), // Pastel dịu mắt
            AppColors.background, // Hòa vào canvas nền app
          ],
          stops: [0.0, 0.42, 0.82, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.spacingBase,
            AppDimens.spacingSm,
            AppDimens.spacingBase,
            AppDimens.spacingMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ----------------------------------------------------
              // Hàng 1: Thời tiết (trái) & Chuông + Avatar (phải)
              // ----------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Viên thuốc thời tiết gọn gàng bên góc trái
                  InkWell(
                    onTap: onWeather,
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                        border: Border.all(color: Colors.white, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowSubtle,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            AppAssets.weather,
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.wb_sunny_rounded,
                              size: 18,
                              color: AppColors.starGold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          weatherAsync.maybeWhen(
                            data: (w) => Text(
                              '${w.temperature.round()}°C • ${w.weatherDescription}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            orElse: () => Text(
                              '26°C • Mây rải rác, trời dịu',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 15,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Nhóm Nút Chuông thông báo + Avatar bên góc phải
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Chuông thông báo
                      InkWell(
                        onTap: onNotifications,
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadowSubtle,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  color: AppColors.textPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                            if (unread > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    unread > 99 ? '99+' : '$unread',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Avatar người dùng
                      InkWell(
                        onTap: onAvatarTap,
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: AppColors.primaryContainer,
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowSubtle,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasAvatar
                              ? AppCachedImage(
                                  imageUrl: avatarUrl!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 100,
                                  errorWidget: _UserInitial(name: name),
                                )
                              : _UserInitial(name: name),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ----------------------------------------------------
              // Hàng 2: Lời chào cá nhân hoá
              // ----------------------------------------------------
              Text(
                name.isNotEmpty ? 'Xin chào, $name 👋' : 'Đô thị Thông minh 360 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18.5,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 10),

              // ----------------------------------------------------
              // Hàng 3: Thanh tìm kiếm thông minh & Nút Báo nhanh
              // ----------------------------------------------------
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowSearch,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: onSearch,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: AppColors.grabGreen,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tìm sự cố, cẩm nang, cứu hộ...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserInitial extends StatelessWidget {
  const _UserInitial({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isEmpty ? 'U' : name[0].toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
