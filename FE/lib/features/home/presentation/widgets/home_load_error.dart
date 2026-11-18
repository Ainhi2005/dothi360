import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';

/// Trạng thái lỗi tải dữ liệu trang chủ (Civic Error State)
class HomeLoadError extends StatelessWidget {
  const HomeLoadError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingLg),
          child: AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Không thể kết nối máy chủ',
            description: 'Vui lòng kiểm tra đường truyền mạng và nhấn thử lại.',
            action: SizedBox(
              width: 160,
              child: AppButton(
                label: 'Thử lại',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ),
          ),
        ),
      );
}
