import 'institution.dart';

class Bank {
  final String id;
  final String name;
  final int sumPoints;
  final List<Institution> institutions;

  Bank({
    required this.id,
    required this.name,
    required this.sumPoints,
    required this.institutions,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'],
      name: json['name'],
      sumPoints: json['sum_points'],
      institutions: (json['institutions'] as List).map((institution) => Institution.fromJson(institution)).toList(),
    );
  }
}
