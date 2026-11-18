import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Header ca trực Cán bộ chuẩn format Grab Gradient đồng bộ với Người dân
class OfficerHeroHeader extends StatelessWidget {
  const OfficerHeroHeader({
    super.key,
    required this.officerName,
    required this.departmentName,
    required this.pendingTasksCount,
    required this.onRefresh,
    this.isOnline = true,
  });

  final String officerName;
  final String departmentName;
  final int pendingTasksCount;
  final VoidCallback onRefresh;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final shortName = officerName.trim().isEmpty
        ? 'Đồng chí'
        : officerName.trim().split(RegExp(r'\s+')).last;

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
              // Hàng 1: Đơn vị công tác & Trạng thái ca trực + Nút làm mới
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Đơn vị công tác
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: AppColors.grabGreenDark,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              departmentName.isNotEmpty
                                  ? departmentName
                                  : 'Đội xử lý sự cố đô thị',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Trạng thái Trực tuyến
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isOnline ? AppColors.success : AppColors.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'Trực tuyến' : 'Ngoại tuyến',
                          style: TextStyle(
                            color: isOnline ? AppColors.successText : AppColors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Nút làm mới
                  InkWell(
                    onTap: onRefresh,
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Hàng 2: Lời chào cán bộ & Tóm tắt ca trực
              Text(
                'Xin chào, $shortName 👮',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                pendingTasksCount > 0
                    ? 'Bạn có $pendingTasksCount nhiệm vụ cần xử lý trong ca trực.'
                    : 'Ca trực hiện tại đã xử lý hết nhiệm vụ tồn đọng.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
