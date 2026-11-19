class ChatSuggestion {
  const ChatSuggestion(
      {required this.id,
      required this.group,
      required this.label,
      required this.question});
  final String id;
  final String group;
  final String label;
  final String question;
  factory ChatSuggestion.fromJson(Map<String, dynamic> json) => ChatSuggestion(
        id: json['id'] as String,
        group: json['group'] as String,
        label: json['label'] as String,
        question: json['question'] as String,
      );
}
