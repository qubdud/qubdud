class PotentialGroup {
  final int id;
  final String name;

  PotentialGroup({
    required this.id,
    required this.name,
  });

  factory PotentialGroup.fromJson(Map<String, dynamic> json) {
    return PotentialGroup(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
