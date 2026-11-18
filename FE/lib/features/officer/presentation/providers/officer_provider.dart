import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/officer_remote_datasource.dart';
import '../../data/models/officer_assignment_model.dart';
import '../../data/models/officer_dashboard_model.dart';

final officerRemoteDataSourceProvider = Provider<OfficerRemoteDataSource>(
  (_) => OfficerRemoteDataSource(),
);

final officerAssignmentsProvider = FutureProvider.autoDispose
    .family<List<OfficerAssignmentModel>, String>((ref, scope) {
  return ref.read(officerRemoteDataSourceProvider).getAssignments(scope);
});

final officerDashboardProvider =
    FutureProvider.autoDispose<OfficerDashboardModel>(
  (ref) => ref.read(officerRemoteDataSourceProvider).getDashboard(),
);

final officerPendingSyncProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.read(officerRemoteDataSourceProvider).pendingSyncCount(),
);

final officerUnreadNotificationsProvider = FutureProvider.autoDispose<int>(
  (ref) =>
      ref.read(officerRemoteDataSourceProvider).getUnreadNotificationCount(),
);
