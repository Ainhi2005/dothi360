import 'package:flutter/material.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/chat_defaults.dart';
import '../../data/models/chat_suggestion.dart';

class ChatSuggestionsPanel extends StatefulWidget {
  const ChatSuggestionsPanel(
      {super.key,
      required this.suggestions,
      required this.enabled,
      required this.onSelected});
  final List<ChatSuggestion> suggestions;
  final bool enabled;
  final ValueChanged<ChatSuggestion> onSelected;
  @override
  State<ChatSuggestionsPanel> createState() => _ChatSuggestionsPanelState();
}

class _ChatSuggestionsPanelState extends State<ChatSuggestionsPanel> {
  String? _group;
  @override
  Widget build(BuildContext context) {
    final groups =
        widget.suggestions.map((item) => item.group).toSet().toList();
    final selected = groups.contains(_group) ? _group : groups.firstOrNull;
    return ExpansionTile(
      title:
          Text(ChatDefaults.suggestionTitle, style: AppTextStyles.titleMedium),
      initiallyExpanded: true,
      childrenPadding:
          const EdgeInsets.symmetric(horizontal: AppDimens.spacingMd),
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height *
                  ChatDefaults.panelHeightFraction),
          child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                        children: groups
                            .map((group) => Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppDimens.spacingSm),
                                  child: ChoiceChip(
                                      label: Text(group),
                                      selected: group == selected,
                                      onSelected: widget.enabled
                                          ? (_) =>
                                              setState(() => _group = group)
                                          : null),
                                ))
                            .toList())),
                const SizedBox(height: AppDimens.spacingSm),
                Wrap(
                    spacing: AppDimens.spacingSm,
                    runSpacing: AppDimens.spacingXs,
                    children: widget.suggestions
                        .where((item) => item.group == selected)
                        .map((item) => ActionChip(
                              label: Text(item.label),
                              onPressed: widget.enabled
                                  ? () => widget.onSelected(item)
                                  : null,
                            ))
                        .toList()),
                const SizedBox(height: AppDimens.spacingSm),
              ])),
        )
      ],
    );
  }
}
