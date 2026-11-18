import '../repositories/incident_repository.dart';
import '../../data/models/incident_response_model.dart';

class SubmitIncidentUseCase {
  final IIncidentRepository repository;

  SubmitIncidentUseCase(this.repository);

  Future<IncidentResponseModel> execute(Map<String, dynamic> requestData) {
    return repository.submitIncident(requestData);
  }
}
