import 'package:flutter_test/flutter_test.dart';
import 'package:urban_issue_app/features/officer/data/models/officer_assignment_model.dart';

void main() {
  test('parses assignment data returned by officer API', () {
    final model = OfficerAssignmentModel.fromJson({
      'id': 'assignment-1',
      'incident_id': 'incident-1',
      'description': 'Cây đổ chắn đường',
      'status': 'ASSIGNED',
      'incident_type_name': 'Cây xanh',
      'department_name': 'Đội cây xanh',
      'assigned_at': '2026-09-27T08:00:00.000Z',
      'priority_score': '87.50',
      'report_count': 3,
    });

    expect(model.id, 'assignment-1');
    expect(model.incidentId, 'incident-1');
    expect(model.priorityScore, 87.5);
    expect(model.reportCount, 3);
    expect(model.isWaiting, isTrue);
  });
}
