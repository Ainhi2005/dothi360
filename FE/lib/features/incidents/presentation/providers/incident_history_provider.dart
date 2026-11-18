import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/incident_history_remote_datasource.dart';
import '../../data/models/incident_detail_model.dart';
import '../../data/models/report_history_model.dart';
import '../../data/models/incident_list_item_model.dart';

final incidentHistoryDataSourceProvider =
    Provider<IncidentHistoryRemoteDataSource>(
  (ref) => IncidentHistoryRemoteDataSource(),
);

final incidentHistoryProvider =
    FutureProvider.autoDispose<List<ReportHistoryModel>>(
  (ref) => ref.read(incidentHistoryDataSourceProvider).getMyReports(),
);

final incidentDetailProvider =
    FutureProvider.autoDispose.family<IncidentDetailModel, String>(
  (ref, id) =>
      ref.read(incidentHistoryDataSourceProvider).getIncidentDetail(id),
);

final publicIncidentsProvider =
    FutureProvider.autoDispose<List<IncidentListItemModel>>(
  (ref) => ref.read(incidentHistoryDataSourceProvider).getIncidents(),
);
