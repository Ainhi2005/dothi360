import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'incident_status_chip.dart';

/// Thanh tiêu đề chi tiết phản ánh (Mã hồ sơ, Trạng thái, Chia sẻ)
class IncidentDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String formattedCode;
  final String? status;
  final VoidCallback? onShare;

  const IncidentDetailAppBar({
    super.key,
    required this.formattedCode,
    this.status,
    this.onShare,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: formattedCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã $formattedCode'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingMd,
        vertical: AppDimens.spacingXs,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/history');
                }
              },
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: AppDimens.iconSizeBase,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.spacingSm),
            Expanded(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _copyCode(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.spacingSm,
                        vertical: AppDimens.spacing2Xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedCode,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.copy_rounded,
                            size: 11,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(width: AppDimens.spacingXs),
                    IncidentStatusChip(status: status!),
                  ],
                ],
              ),
            ),
            InkWell(
              onTap: onShare,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.share_outlined,
                  size: AppDimens.iconSizeSm,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
