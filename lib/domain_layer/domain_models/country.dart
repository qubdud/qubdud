class Country {
  final String id;
  final String name;
  final String countryCode;

  Country({required this.id, required this.name, required this.countryCode});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country_code': countryCode,
    };
  }
}
