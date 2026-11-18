import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_guide_model.dart';

class GuideStepCard extends StatefulWidget {
  const GuideStepCard({
    super.key,
    required this.step,
  });

  final EmergencyStepModel step;

  @override
  State<GuideStepCard> createState() => _GuideStepCardState();
}

class _GuideStepCardState extends State<GuideStepCard> {
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd - 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd + 4),
        border: Border.all(
          color: _isCompleted
              ? AppColors.emergencySuccessBorder
              : AppColors.divider.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isCompleted = !_isCompleted),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: 2),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _isCompleted
                      ? AppColors.emergencyHotlineBg
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.emergencyHotlineBg,
                    width: 2,
                  ),
                ),
                child: _isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.spacingSm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'BƯỚC ${widget.step.stepNumber}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.emergencyHotlineBg,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.step.tag,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.spacingXs),
                Text(
                  widget.step.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                    decoration: _isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: AppDimens.spacingXs),
                Text(
                  widget.step.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
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
