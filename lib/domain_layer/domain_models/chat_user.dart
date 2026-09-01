import 'dart:convert';

/// Model reprezentujący użytkownika czatu
class ChatUser {
  final String uid;
  final String name;
  final String countryCode;

  ChatUser({
    required this.uid,
    required this.name,
    required this.countryCode,
  });

  /// Tworzy obiekt `ChatUser` z mapy (JSON)
  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      uid: json['token'] as String,
      name: json['name'] as String,
      countryCode: json['country_code'] as String,
    );
  }
}
