import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/submit_incident_usecase.dart';
import '../../data/datasources/incident_remote_datasource.dart';
import '../../data/repositories/incident_repository_impl.dart';

// Providers setup
final remoteDataSourceProvider = Provider((ref) => IncidentRemoteDataSource());
final repositoryProvider = Provider(
    (ref) => IncidentRepositoryImpl(ref.read(remoteDataSourceProvider)));
final submitUseCaseProvider =
    Provider((ref) => SubmitIncidentUseCase(ref.read(repositoryProvider)));

class SubmitIncidentNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> submit(Map<String, dynamic> requestData) async {
    final useCase = ref.read(submitUseCaseProvider);
    state = const AsyncValue.loading();
    try {
      final response = await useCase.execute(requestData);
      if (response.success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error(
            response.message ?? 'Unknown error', StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final submitIncidentProvider =
    AsyncNotifierProvider<SubmitIncidentNotifier, void>(() {
  return SubmitIncidentNotifier();
});
