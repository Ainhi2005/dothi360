import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Thanh tiến trình 3 bước chuẩn Civic cho luồng Tạo phản ánh
class StepperWidget extends StatelessWidget {
  final int currentStep;
  const StepperWidget({super.key, this.currentStep = 1});

  static const List<String> _stepTitles = [
    'Thông tin',
    'AI kiểm tra',
    'Xác nhận',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingSm,
        vertical: AppDimens.spacingMd,
      ),
      child: Row(
        children: [
          for (int i = 0; i < _stepTitles.length; i++) ...[
            if (i > 0) _buildConnector(isCompleted: currentStep > i),
            _buildStepNode(
              stepNumber: i + 1,
              title: _stepTitles[i],
              state: _getStepState(i + 1),
            ),
          ],
        ],
      ),
    );
  }

  _StepVisualState _getStepState(int stepNumber) {
    if (stepNumber < currentStep) return _StepVisualState.completed;
    if (stepNumber == currentStep) return _StepVisualState.active;
    return _StepVisualState.upcoming;
  }

  Widget _buildConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2.0,
        margin: const EdgeInsets.only(
          bottom: AppDimens.spacingLg,
          left: AppDimens.spacingXs,
          right: AppDimens.spacingXs,
        ),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.primary : AppColors.divider,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
      ),
    );
  }

  Widget _buildStepNode({
    required int stepNumber,
    required String title,
    required _StepVisualState state,
  }) {
    final isCompleted = state == _StepVisualState.completed;
    final isActive = state == _StepVisualState.active;

    Color badgeBg;
    Color badgeBorder;
    Widget badgeContent;
    Color textColor;
    FontWeight textWeight;

    if (isCompleted) {
      badgeBg = AppColors.primary;
      badgeBorder = AppColors.primary;
      badgeContent = const Icon(
        Icons.check_rounded,
        size: AppDimens.iconSizeSm,
        color: Colors.white,
      );
      textColor = AppColors.textPrimary;
      textWeight = FontWeight.w500;
    } else if (isActive) {
      badgeBg = AppColors.primary;
      badgeBorder = AppColors.primary;
      badgeContent = Text(
        '$stepNumber',
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      );
      textColor = AppColors.textPrimary;
      textWeight = FontWeight.w700;
    } else {
      badgeBg = AppColors.surface;
      badgeBorder = AppColors.border;
      badgeContent = Text(
        '$stepNumber',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
      textColor = AppColors.textDisabled;
      textWeight = FontWeight.w400;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28.0,
          height: 28.0,
          decoration: BoxDecoration(
            color: badgeBg,
            shape: BoxShape.circle,
            border: Border.all(color: badgeBorder, width: 1.5),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: badgeContent,
        ),
        const SizedBox(height: AppDimens.spacingXs + 2),
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: textColor,
            fontWeight: textWeight,
          ),
        ),
      ],
    );
  }
}

enum _StepVisualState {
  completed,
  active,
  upcoming,
}
