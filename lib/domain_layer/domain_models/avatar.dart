class Avatar {
  final String id;
  final String name;

  Avatar({
    required this.id,
    required this.name,
  });

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      id: json['id'],
      name: json['name'],
    );
  }
}
