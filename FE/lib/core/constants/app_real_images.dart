class AppRealImages {
  AppRealImages._();

  /// 1. Ngập lụt đô thị / Nước ngập sâu
  static const String incidentFlood =
      'https://res.cloudinary.com/dcapucva9/image/upload/v1789883342/urban-incidents/media_1789883333122_82.jpg';

  /// 2. Hư hỏng đường bộ / Cầu cống
  static const String incidentRoadDamage =
      'https://res.cloudinary.com/dcapucva9/image/upload/v1791628290/urban-incidents/ck6x3qx7rbkmvysnm3wp.jpg';

  /// 3. Ùn tắc giao thông / Phương tiện
  static const String incidentTraffic =
      'https://res.cloudinary.com/dcapucva9/image/upload/v1791642768/urban-incidents/ik7xee0xjbeuiujpy1az.jpg';

  /// 4. Sụt lún ổ gà nguy hiểm
  static const String incidentPothole =
      'https://res.cloudinary.com/dcapucva9/image/upload/v1792255372/urban-incidents/kfrq8pnbk8hhsle29bfk.jpg';

  /// 5. Bể ống nước / Nước tràn mặt đường
  static const String incidentPipeBurst =
      'https://res.cloudinary.com/dcapucva9/image/upload/v1792255374/urban-incidents/nxivknimy0wjqghu1kae.jpg';

  /// 6. Sự cố vừa giải quyết xong / Nghiệm thu
  static const String incidentResolved =
      'https://res.cloudinary.com/dcapucva9/image/upload/v1793423551/urban-incidents/w35ua4cyzfxtb7ibekfm.jpg';

  static const List<String> list = [
    incidentFlood,
    incidentRoadDamage,
    incidentTraffic,
    incidentPothole,
    incidentPipeBurst,
    incidentResolved,
  ];

  static String getByIndex(int index) {
    if (list.isEmpty) return incidentFlood;
    return list[index % list.length];
  }
}
