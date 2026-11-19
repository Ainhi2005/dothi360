import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../data/chat_defaults.dart';
import '../../data/chat_service.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer(
      {super.key,
      required this.controller,
      required this.sending,
      required this.onSend});
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        color: AppColors.surface,
        child: Row(children: [
          Expanded(
              child: TextField(
                  controller: controller,
                  maxLength: ChatService.maxMessageLength,
                  textInputAction: TextInputAction.send,
                  onSubmitted: sending ? null : (_) => onSend(),
                  decoration: const InputDecoration(
                      hintText: ChatDefaults.inputHint, counterText: ''))),
          const SizedBox(width: AppDimens.spacingSm),
          IconButton.filled(
              tooltip: 'Gửi câu hỏi',
              onPressed: sending ? null : onSend,
              icon: const Icon(Icons.send)),
        ]),
      );
}
