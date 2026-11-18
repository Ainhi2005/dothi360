import '../../data/models/incident_response_model.dart';

abstract class IIncidentRepository {
  Future<IncidentResponseModel> submitIncident(
      Map<String, dynamic> requestData);
}
