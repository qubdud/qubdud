class PlatformVersion {
  final int versionCode;
  final String versionName;
  final String link;

  PlatformVersion({
    required this.versionCode,
    required this.versionName,
    required this.link,
  });

  factory PlatformVersion.fromJson(Map<String, dynamic> json) {
    return PlatformVersion(
      versionCode: json['versionCode'],
      versionName: json['versionName'],
      link: json['link'],
    );
  }
}

class PlatformData {
  final PlatformVersion android;
  final PlatformVersion ios;

  PlatformData({
    required this.android,
    required this.ios,
  });

  factory PlatformData.fromJson(Map<String, dynamic> json) {
    return PlatformData(
      android: PlatformVersion.fromJson(json['android']),
      ios: PlatformVersion.fromJson(json['ios']),
    );
  }
}

class Module {
  final String name;
  final bool isEnabled;
  final DateTime startDate;
  final DateTime endDate;
  final String description;

  Module({
    required this.name,
    required this.isEnabled,
    required this.startDate,
    required this.endDate,
    required this.description,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      name: json['name'],
      isEnabled: json['isEnabled'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isEnabled': isEnabled,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'description': description,
    };
  }
}

class AppData {
  final PlatformData appPlatform;
  final List<Module> appModules;
  final String appCurrentStage;

  AppData({
    required this.appPlatform,
    required this.appModules,
    required this.appCurrentStage,
  });

  factory AppData.fromJson(Map<String, dynamic> json) {
    return AppData(
      appPlatform: PlatformData.fromJson(json['appPlatform']),
      appModules: (json['appModules'] as List).map((module) => Module.fromJson(module)).toList(),
      appCurrentStage: json['appCurrentStage'],
    );
  }
}
