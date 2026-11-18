class InterestedAreaModel {
  const InterestedAreaModel({required this.id,required this.name,required this.latitude,required this.longitude,required this.radiusM,required this.notificationsEnabled,required this.isActive,required this.incidentCount,required this.newCount});
  final String id,name;final double latitude,longitude;final int radiusM,incidentCount,newCount;final bool notificationsEnabled,isActive;
  factory InterestedAreaModel.fromJson(Map<String,dynamic> j)=>InterestedAreaModel(id:'${j['id']}',name:'${j['name']}',latitude:double.tryParse('${j['latitude']}')??0,longitude:double.tryParse('${j['longitude']}')??0,radiusM:int.tryParse('${j['radius_m']}')??1000,notificationsEnabled:j['notifications_enabled']==true,isActive:j['is_active']==true,incidentCount:int.tryParse('${j['incident_count']}')??0,newCount:int.tryParse('${j['new_count']}')??0);
}
