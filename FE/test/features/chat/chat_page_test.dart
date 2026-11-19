import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_issue_app/features/chat/data/chat_defaults.dart';
import 'package:urban_issue_app/features/chat/data/chat_service.dart';
import 'package:urban_issue_app/features/chat/data/models/chat_suggestion.dart';
import 'package:urban_issue_app/features/chat/presentation/pages/chat_page.dart';

class LocalChatService extends ChatService {
  LocalChatService({this.catalogFails = false}) : super(dio: Dio());
  final bool catalogFails;
  String? selectedId, message;
  List<Map<String, String>>? sentHistory;
  @override
  Future<List<ChatSuggestion>> loadSuggestions() async {
    if (catalogFails) throw Exception('Offline catalog');
    return ChatDefaults.suggestions;
  }

  @override
  Future<String> send(String message,
      {List<Map<String, String>> history = const [],
      String? suggestionId}) async {
    this.message = message;
    selectedId = suggestionId;
    sentHistory = history;
    return 'Không tìm thấy phản ánh phù hợp của bạn.';
  }
}

void main() {
  testWidgets('chọn câu hỏi gửi đúng mã và vẫn gửi được câu tự nhập',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = LocalChatService();
    await tester.pumpWidget(MaterialApp(home: ChatPage(service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Lịch sử phản ánh'));
    await tester.pumpAndSettle();
    expect(service.selectedId, 'history');
    expect(service.message, 'Kiểm tra lịch sử phản ánh của tôi');
    expect(
        find.text('Không tìm thấy phản ánh phù hợp của bạn.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(service.selectedId, isNull);
    expect(service.message, 'hi');
    expect(service.sentHistory?.length, 2);
  });
  testWidgets('catalog lỗi vẫn có gợi ý và bàn phím không làm tràn bố cục',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(
        home: ChatPage(service: LocalChatService(catalogFails: true))));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'Lịch sử phản ánh'), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
