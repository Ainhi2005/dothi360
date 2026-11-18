import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_issue_app/features/incidents/data/models/report_history_model.dart';
import 'package:urban_issue_app/features/incidents/presentation/widgets/history_report_card.dart';

void main() {
  testWidgets('shows report data and handles tap', (tester) async {
    var tapped = false;
    final report = ReportHistoryModel(
      reportId: 'report-1',
      incidentId: '12345678-abcd',
      description: 'Mặt đường xuất hiện ổ gà lớn',
      incidentTypeName: 'Mặt đường',
      status: 'IN_PROGRESS',
      createdAt: DateTime.utc(2026, 9, 27, 10),
      reportCount: 2,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HistoryReportCard(report: report, onTap: () => tapped = true),
      ),
    ));

    expect(find.text('Mặt đường'), findsOneWidget);
    expect(find.text('Đang xử lý'), findsOneWidget);
    expect(find.textContaining('#PA-2609-BCD'), findsOneWidget);
    await tester.tap(find.text('Mặt đường'));
    expect(tapped, isTrue);
  });
}
