class NotificationModel {
  final String id;
  final String category;
  final String route;
  final String title;
  final String body;
  final NotificationAvatar avatar;
  final String readAt;
  final String createdAtFormatted;
  final String postId;
  final String stage;

  NotificationModel({
    required this.id,
    required this.category,
    required this.route,
    required this.title,
    required this.body,
    required this.avatar,
    required this.readAt,
    required this.createdAtFormatted,
    required this.postId,
    required this.stage
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      route: json['data']['route'] ?? '',
      title: json['data']['title'] ?? '',
      body: json['data']['body'] ?? '',
        avatar: NotificationAvatar.fromJson(
            (json['data']['avatar'] is String || json['data']['avatar'] == null)
                ? {}
                : json['data']['avatar']
        ),
      readAt: json['read_at'] ?? '',
      createdAtFormatted: json['created_at_formatted'] ?? '',
      postId: json['data']?['post_id'] ?? '',
      stage: json['data']?['stage'] ?? ''
    );
  }
}

class NotificationAvatar {
  final String type;
  final String countryName;
  final String countryCode;
  final int vehicleType;
  final int vehicleColor;

  NotificationAvatar({
    required this.type,
    required this.countryName,
    required this.countryCode,
    required this.vehicleType,
    required this.vehicleColor,
  });

  factory NotificationAvatar.fromJson(Map<String, dynamic> json) {
    return NotificationAvatar(
      type: json['type'] ?? '', // Typ awatara (np. country, team)

      // Jeśli typ awatara to "country", pobieramy country_name i country_code
      countryName: json['type'] == 'country' ? json['country_name'] ?? '' : '',
      countryCode: json['type'] == 'country' ? json['country_code'] ?? '' : '',

      // Jeśli typ awatara to "team", pobieramy vehicle_type i vehicle_color
      vehicleType: json['type'] == 'team' ? json['vehicle_type'] ?? 0 : 0,
      vehicleColor: json['type'] == 'team' ? json['vehicle_color'] ?? 0 : 0,
    );
  }
}
