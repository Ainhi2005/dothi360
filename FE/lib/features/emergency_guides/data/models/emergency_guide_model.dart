class EmergencyPhoneModel {
  const EmergencyPhoneModel({required this.label, required this.number});
  final String label;
  final String number;

  factory EmergencyPhoneModel.fromJson(Map<String, dynamic> json) =>
      EmergencyPhoneModel(
        label: json['label']?.toString() ?? '',
        number: json['number']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'number': number,
      };
}

class EmergencyStepModel {
  const EmergencyStepModel({
    required this.stepNumber,
    required this.tag,
    required this.title,
    required this.description,
  });

  final int stepNumber;
  final String tag;
  final String title;
  final String description;

  factory EmergencyStepModel.fromRaw(int index, String raw) {
    final clean = raw.trim();
    String tag = _defaultTag(index);
    String remaining = clean;

    if (remaining.startsWith('[') && remaining.contains(']')) {
      final closeIdx = remaining.indexOf(']');
      tag = remaining.substring(1, closeIdx).trim();
      remaining = remaining.substring(closeIdx + 1).trim();
    }

    if (remaining.contains(':')) {
      final parts = remaining.split(':');
      final title = parts[0].trim();
      final desc = parts.sublist(1).join(':').trim();
      return EmergencyStepModel(
        stepNumber: index + 1,
        tag: tag,
        title: title,
        description: desc.isNotEmpty ? desc : _defaultDesc(index),
      );
    }

    return EmergencyStepModel(
      stepNumber: index + 1,
      tag: tag,
      title: remaining,
      description: _defaultDesc(index),
    );
  }

  static String _defaultTag(int index) => switch (index) {
        0 => 'Khẩn cấp',
        1 => 'Bảo vệ thở',
        2 => 'Báo tin',
        _ => 'Thực hiện',
      };

  static String _defaultDesc(int index) => switch (index) {
        0 => 'Bấm chuông báo động hoặc hô to để người xung quanh biết và hỗ trợ.',
        1 => 'Hạ thấp người, tránh khói khí độc và di chuyển theo lối thoát hiểm an toàn.',
        2 => 'Nêu rõ vị trí xảy ra sự cố và tình trạng người gặp nạn cho cứu hộ.',
        _ => 'Thực hiện tuần tự và giữ bình tĩnh để đảm bảo an toàn tuyệt đối.',
      };

  factory EmergencyStepModel.fromJson(Map<String, dynamic> json) =>
      EmergencyStepModel(
        stepNumber: json['step_number'] is int
            ? json['step_number'] as int
            : int.tryParse('${json['step_number']}') ?? 1,
        tag: json['tag']?.toString() ?? 'Khẩn cấp',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'step_number': stepNumber,
        'tag': tag,
        'title': title,
        'description': description,
      };
}

class EmergencyAvoidModel {
  const EmergencyAvoidModel({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  factory EmergencyAvoidModel.fromRaw(String raw) {
    final clean = raw.trim();
    if (clean.contains(':')) {
      final parts = clean.split(':');
      final title = parts[0].trim();
      final desc = parts.sublist(1).join(':').trim();
      return EmergencyAvoidModel(
        title: title,
        description: desc.isNotEmpty
            ? desc
            : 'Hành động này tiềm ẩn nguy cơ cao gây nguy hiểm cho tính mạng.',
      );
    }
    return EmergencyAvoidModel(
      title: clean,
      description:
          'Hành động này tiềm ẩn nguy cơ cao gây nguy hiểm cho tính mạng.',
    );
  }

  factory EmergencyAvoidModel.fromJson(Map<String, dynamic> json) =>
      EmergencyAvoidModel(
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
      };
}

class EmergencyGuideModel {
  const EmergencyGuideModel({
    required this.id,
    required this.code,
    required this.title,
    required this.summary,
    required this.icon,
    required this.accent,
    required this.doNow,
    required this.avoid,
    required this.phoneNumbers,
  });

  final String id;
  final String code;
  final String title;
  final String summary;
  final String icon;
  final String accent;
  final List<String> doNow;
  final List<String> avoid;
  final List<EmergencyPhoneModel> phoneNumbers;

  String get dangerLevel => switch (accent.toLowerCase()) {
        'warning' => 'CẢNH BÁO NGUY HIỂM',
        'info' => 'CẢNH BÁO NGUY HIỂM',
        'success' => 'MỨC ĐỘ AN TOÀN',
        _ => 'MỨC NGUY HIỂM CAO',
      };

  List<EmergencyStepModel> get resolvedSteps => doNow
      .asMap()
      .entries
      .map((e) => EmergencyStepModel.fromRaw(e.key, e.value))
      .toList();

  List<EmergencyAvoidModel> get resolvedAvoidItems =>
      avoid.map((e) => EmergencyAvoidModel.fromRaw(e)).toList();

  factory EmergencyGuideModel.fromJson(Map<String, dynamic> json) =>
      EmergencyGuideModel(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        summary: json['summary']?.toString() ?? '',
        icon: json['icon']?.toString() ?? 'warning',
        accent: json['accent']?.toString() ?? 'danger',
        doNow: List<String>.from(json['do_now'] ?? const []),
        avoid: List<String>.from(json['avoid'] ?? const []),
        phoneNumbers: (json['phone_numbers'] as List<dynamic>? ?? const [])
            .map((item) => EmergencyPhoneModel.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'summary': summary,
        'icon': icon,
        'accent': accent,
        'do_now': doNow,
        'avoid': avoid,
        'phone_numbers': phoneNumbers.map((e) => e.toJson()).toList(),
      };
}
