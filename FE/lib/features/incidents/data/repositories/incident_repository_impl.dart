import '../../domain/repositories/incident_repository.dart';
import '../models/incident_response_model.dart';
import '../datasources/incident_remote_datasource.dart';

class IncidentRepositoryImpl implements IIncidentRepository {
  final IncidentRemoteDataSource remoteDataSource;

  IncidentRepositoryImpl(this.remoteDataSource);

  @override
  Future<IncidentResponseModel> submitIncident(
      Map<String, dynamic> requestData) async {
    try {
      final response = await remoteDataSource.submitIncident(requestData);
      return IncidentResponseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to submit incident: $e');
    }
  }
}
