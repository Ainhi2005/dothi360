import 'models/chat_suggestion.dart';

class ChatDefaults {
  const ChatDefaults._();
  static const welcome =
      'Xin chào! Tôi hỗ trợ sử dụng Đô Thị 360 và tra cứu phản ánh của chính bạn. Chọn câu hỏi gợi ý để nhận hỗ trợ nhanh hoặc nhập câu hỏi của bạn.';
  static const suggestionTitle = 'Câu hỏi gợi ý';
  static const inputHint = 'Hỏi về phản ánh hoặc cách sử dụng...';
  static const scrollDuration = Duration(milliseconds: 200);
  static const panelHeightFraction = .26;
  // Available while the shared server catalog is loading or temporarily unavailable.
  static const suggestions = [
    ChatSuggestion(
        id: 'history',
        group: 'Tra cứu phản ánh',
        label: 'Lịch sử phản ánh',
        question: 'Kiểm tra lịch sử phản ánh của tôi'),
    ChatSuggestion(
        id: 'latest',
        group: 'Tra cứu phản ánh',
        label: 'Phản ánh gần nhất',
        question: 'Phản ánh gần nhất của tôi đang ở trạng thái nào?'),
    ChatSuggestion(
        id: 'active',
        group: 'Tra cứu phản ánh',
        label: 'Đang xử lý',
        question: 'Những phản ánh nào của tôi đang được xử lý?'),
    ChatSuggestion(
        id: 'send_report',
        group: 'Hướng dẫn sử dụng',
        label: 'Cách gửi phản ánh',
        question: 'Làm thế nào để gửi phản ánh sự cố?'),
    ChatSuggestion(
        id: 'password',
        group: 'Tài khoản',
        label: 'Đổi mật khẩu',
        question: 'Tôi đổi mật khẩu tài khoản ở đâu?'),
    ChatSuggestion(
        id: 'help',
        group: 'Trợ giúp',
        label: 'Bạn giúp được gì?',
        question: 'Trợ lý có thể hỗ trợ những gì?'),
  ];
}
