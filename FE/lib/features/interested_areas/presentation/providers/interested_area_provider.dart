import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/interested_area_remote_datasource.dart';
import '../../data/models/interested_area_model.dart';

final interestedAreaDataSourceProvider=Provider((_)=>InterestedAreaRemoteDataSource());
final interestedAreasProvider=AsyncNotifierProvider<InterestedAreasNotifier,List<InterestedAreaModel>>(InterestedAreasNotifier.new);
class InterestedAreasNotifier extends AsyncNotifier<List<InterestedAreaModel>>{
  @override Future<List<InterestedAreaModel>> build()=>ref.read(interestedAreaDataSourceProvider).list();
  Future<void> save({String? id,required String name,required double latitude,required double longitude,required int radiusM,required bool notificationsEnabled})async{await ref.read(interestedAreaDataSourceProvider).save(id:id,name:name,latitude:latitude,longitude:longitude,radiusM:radiusM,notificationsEnabled:notificationsEnabled);state=AsyncData(await ref.read(interestedAreaDataSourceProvider).list());}
  Future<void> remove(String id)async{await ref.read(interestedAreaDataSourceProvider).remove(id);state=AsyncData(await ref.read(interestedAreaDataSourceProvider).list());}
}
