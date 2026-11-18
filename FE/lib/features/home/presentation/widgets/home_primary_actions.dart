import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_dimens.dart';
import 'home_action_card.dart';

class HomePrimaryActions extends StatelessWidget {
  const HomePrimaryActions({
    super.key,
    required this.onCreate,
    required this.onHistory,
  });

  final VoidCallback onCreate;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final create = HomeActionCard(
            image: AppAssets.camera,
            title: 'Tạo phản ánh mới',
            description: 'Chụp ảnh, mô tả và gửi ngay đến cơ quan chức năng',
            onTap: onCreate,
            primary: true,
          );
          final history = HomeActionCard(
            image: AppAssets.profile,
            title: 'Theo dõi hồ sơ',
            description: 'Xem tiến độ xử lý các phản ánh của bạn',
            onTap: onHistory,
          );
          if (constraints.maxWidth < AppDimens.homeActionRowBreakpoint) {
            return Column(
              children: [
                SizedBox(height: AppDimens.homeActionHeight, child: create),
                const SizedBox(height: AppDimens.spacingSm),
                SizedBox(height: AppDimens.homeActionHeight, child: history),
              ],
            );
          }
          return SizedBox(
            height: AppDimens.homeActionHeight,
            child: Row(
              children: [
                Expanded(child: create),
                const SizedBox(width: AppDimens.spacingSm),
                Expanded(child: history),
              ],
            ),
          );
        },
      );
}
