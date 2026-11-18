import '../../../../core/network/dio_client.dart';
import '../models/interested_area_model.dart';

class InterestedAreaRemoteDataSource {
  final _dio=DioClient().dio;
  Future<List<InterestedAreaModel>> list() async {final r=await _dio.get('/interested-areas');return List<Map<String,dynamic>>.from(r.data['data']??const[]).map(InterestedAreaModel.fromJson).toList();}
  Future<void> save({String? id,required String name,required double latitude,required double longitude,required int radiusM,required bool notificationsEnabled}) async {final data={'name':name,'latitude':latitude,'longitude':longitude,'radius_m':radiusM,'notifications_enabled':notificationsEnabled};if(id==null){await _dio.post('/interested-areas',data:data);}else{await _dio.put('/interested-areas/$id',data:data);}}
  Future<void> remove(String id) async {await _dio.delete('/interested-areas/$id');}
  Future<Map<String,dynamic>> incidents(String id) async {final r=await _dio.get('/interested-areas/$id/incidents');return Map<String,dynamic>.from(r.data);}
  Future<List<Map<String,dynamic>>> searchPlaces(String query,{double? latitude,double? longitude}) async {final r=await _dio.get('/interested-areas/search/places',queryParameters:{'q':query,'lat':latitude,'lng':longitude});return List<Map<String,dynamic>>.from(r.data['data']??const[]);}
}
