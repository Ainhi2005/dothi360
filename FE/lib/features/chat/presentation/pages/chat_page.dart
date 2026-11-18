import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../data/chat_service.dart';
import '../widgets/chat_message_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _messages = <({String text, bool user})>[
    (text: 'Xin chào! Tôi có thể kiểm tra trạng thái các phản ánh của bạn từ dữ liệu hệ thống.', user: false),
  ];
  bool _sending = false;

  Future<void> _send([String? suggestion]) async {
    final text = (suggestion ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() { _messages.add((text: text, user: true)); _sending = true; _input.clear(); });
    try {
      final reply = await ChatService().send(text);
      if (mounted) setState(() => _messages.add((text: reply, user: false)));
    } catch (_) {
      if (mounted) setState(() => _messages.add((text: 'Không thể kết nối trợ lý. Vui lòng thử lại.', user: false)));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  void dispose() { _input.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Trợ lý đô thị AI')),
    body: SafeArea(child: Column(children: [
      Expanded(child: ListView(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        children: [
          Wrap(spacing: AppDimens.spacingSm, children: [
            ActionChip(label: const Text('Phản ánh gần nhất'), onPressed: () => _send('Cho tôi biết trạng thái phản ánh gần nhất')),
            ActionChip(label: const Text('Đang xử lý'), onPressed: () => _send('Những phản ánh nào của tôi đang được xử lý?')),
          ]),
          const SizedBox(height: AppDimens.spacingMd),
          ..._messages.map((item) => ChatMessageBubble(message: item.text, isUser: item.user)),
          if (_sending) const LinearProgressIndicator(),
        ],
      )),
      Container(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        color: AppColors.surface,
        child: Row(children: [
          Expanded(child: TextField(controller: _input, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Hỏi về phản ánh của bạn...'))),
          const SizedBox(width: AppDimens.spacingSm),
          IconButton.filled(onPressed: _sending ? null : _send, icon: const Icon(Icons.send)),
        ]),
      ),
    ])),
  );
}
