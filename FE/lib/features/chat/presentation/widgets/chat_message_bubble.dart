import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message, required this.isUser});
  final String message;
  final bool isUser;

  @override
  Widget build(BuildContext context) => Align(
    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
      margin: const EdgeInsets.only(bottom: AppDimens.spacingSm),
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary : AppColors.surface,
        border: isUser ? null : Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: isUser ? AppColors.surface : AppColors.textPrimary)),
    ),
  );
}
