import 'package:flutter_test/flutter_test.dart';
import 'package:urban_issue_app/features/incidents/data/models/report_history_model.dart';

void main() {
  test('parses nested incident history response', () {
    final model = ReportHistoryModel.fromJson({
      'id': 'report-1',
      'incident_id': 'incident-1',
      'description': 'Đèn đường bị hỏng',
      'created_at': '2026-09-27T10:00:00.000Z',
      'incident': {
        'status': 'IN_PROGRESS',
        'priority_score': '72.50',
        'report_count': 3,
        'incident_type': {'name': 'Đèn đường'},
      },
      'media': [
        {'file_url': 'https://example.test/image.jpg'},
      ],
    });

    expect(model.reportId, 'report-1');
    expect(model.incidentId, 'incident-1');
    expect(model.incidentTypeName, 'Đèn đường');
    expect(model.status, 'IN_PROGRESS');
    expect(model.priorityScore, 72.5);
    expect(model.reportCount, 3);
    expect(model.imageUrls, ['https://example.test/image.jpg']);
  });
}
