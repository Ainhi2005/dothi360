import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_button.dart';

class ReportSuccessActions extends StatelessWidget {
  const ReportSuccessActions({
    required this.canViewDetail,
    required this.onCreateAnother,
    required this.onViewDetail,
    super.key,
  });

  final bool canViewDetail;
  final VoidCallback onCreateAnother;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Tạo phản ánh khác',
              type: AppButtonType.outline,
              onPressed: onCreateAnother,
            ),
          ),
          const SizedBox(width: AppDimens.spacingMd),
          Expanded(
            child: AppButton(
              label: canViewDetail ? 'Xem chi tiết' : 'Xem lịch sử',
              icon: Icons.arrow_forward,
              onPressed: onViewDetail,
            ),
          ),
        ],
      ),
    );
  }
}
