import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/emergency_guide_remote_datasource.dart';
import '../../data/models/emergency_guide_model.dart';

final emergencyGuideDataSourceProvider = Provider((ref) => EmergencyGuideRemoteDataSource());
final emergencyGuidesProvider = FutureProvider<List<EmergencyGuideModel>>((ref) => ref.read(emergencyGuideDataSourceProvider).getAll());
final emergencyGuideDetailProvider = FutureProvider.family<EmergencyGuideModel, String>((ref, id) => ref.read(emergencyGuideDataSourceProvider).getOne(id));
