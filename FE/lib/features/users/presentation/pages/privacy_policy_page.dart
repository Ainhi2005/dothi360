import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chính sách quyền riêng tư',
            style: AppTextStyles.titleMedium),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.spacingLg),
        children: const [
          Text('Dữ liệu được sử dụng thế nào?',
              style: AppTextStyles.headingSmall),
          SizedBox(height: AppDimens.spacingMd),
          Text(
              'Đô Thị 360 sử dụng thông tin tài khoản để xác định người gửi và thông báo tiến độ xử lý.',
              style: AppTextStyles.bodyLarge),
          SizedBox(height: AppDimens.spacingLg),
          Text('Ảnh và vị trí', style: AppTextStyles.titleMedium),
          SizedBox(height: AppDimens.spacingSm),
          Text(
              'Ảnh hiện trường và tọa độ GPS chỉ phục vụ xác minh, phát hiện phản ánh trùng và điều phối đơn vị xử lý.',
              style: AppTextStyles.bodyMedium),
          SizedBox(height: AppDimens.spacingLg),
          Text('Bảo mật tài khoản', style: AppTextStyles.titleMedium),
          SizedBox(height: AppDimens.spacingSm),
          Text(
              'Mật khẩu được lưu dưới dạng mã hóa. Không chia sẻ mật khẩu hoặc mã đăng nhập cho người khác.',
              style: AppTextStyles.bodyMedium),
          SizedBox(height: AppDimens.spacingLg),
          Text('Quyền của bạn', style: AppTextStyles.titleMedium),
          SizedBox(height: AppDimens.spacingSm),
          Text(
              'Bạn có thể xem, cập nhật thông tin cá nhân và theo dõi toàn bộ phản ánh đã gửi trong ứng dụng.',
              style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
