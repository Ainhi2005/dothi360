import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../data/chat_defaults.dart';
import '../../data/chat_service.dart';
import '../../data/models/chat_suggestion.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_suggestions_panel.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.service});
  final ChatService? service;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <({String text, bool user})>[
    (text: ChatDefaults.welcome, user: false)
  ];
  late final ChatService _service;
  List<ChatSuggestion> _suggestions = ChatDefaults.suggestions;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ChatService();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final items = await _service.loadSuggestions();
      if (mounted && items.isNotEmpty) setState(() => _suggestions = items);
    } catch (_) {
      // Keep basic questions available when the catalog cannot be loaded.
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: ChatDefaults.scrollDuration, curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send([ChatSuggestion? suggestion]) async {
    final text = (suggestion?.question ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    final previous = _messages.skip(1).toList();
    final history = previous
        .skip(previous.length > ChatService.historyLimit
            ? previous.length - ChatService.historyLimit
            : 0)
        .map((item) => {
              'role': item.user ? 'user' : 'assistant',
              'content': item.text.length > ChatService.maxMessageLength
                  ? item.text.substring(0, ChatService.maxMessageLength)
                  : item.text,
            })
        .toList();
    setState(() {
      _messages.add((text: text, user: true));
      _sending = true;
      _input.clear();
    });
    _scrollToLatest();
    try {
      final reply = await _service.send(text,
          history: history, suggestionId: suggestion?.id);
      if (mounted) setState(() => _messages.add((text: reply, user: false)));
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['message']?.toString() : null;
      if (mounted) {
        setState(() => _messages.add((
              text: message ?? 'Không thể kết nối trợ lý. Vui lòng thử lại.',
              user: false
            )));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _messages.add((
              text: 'Không thể kết nối trợ lý. Vui lòng thử lại.',
              user: false
            )));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToLatest();
      }
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Trợ lý đô thị')),
        body: SafeArea(
            child: Column(children: [
          Expanded(
              child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppDimens.spacingMd),
                  itemCount: _messages.length,
                  itemBuilder: (_, index) => ChatMessageBubble(
                      message: _messages[index].text,
                      isUser: _messages[index].user))),
          if (_sending) const LinearProgressIndicator(),
          if (MediaQuery.viewInsetsOf(context).bottom == 0)
            ChatSuggestionsPanel(
                suggestions: _suggestions,
                enabled: !_sending,
                onSelected: _send),
          ChatComposer(
              controller: _input, sending: _sending, onSend: () => _send()),
        ])),
      );
}
