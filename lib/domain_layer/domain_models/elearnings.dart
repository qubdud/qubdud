class ElearningData {
  final String deadline;
  final List<Elearning> elearnings;

  ElearningData({
    required this.deadline,
    required this.elearnings,
  });

  factory ElearningData.fromJson(Map<String, dynamic> json) {
    return ElearningData(
      deadline: json['deadline'],
      elearnings: (json['elearnings'] as List)
          .map((e) => Elearning.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deadline': deadline,
      'elearnings': elearnings.map((e) => e.toJson()).toList(),
    };
  }
}

class Elearning {
  final String id;
  final String name;
  final String link;

  Elearning({
    required this.id,
    required this.name,
    required this.link,
  });

  factory Elearning.fromJson(Map<String, dynamic> json) {
    return Elearning(
      id: json['id'],
      name: json['name'],
      link: json['link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'link': link,
    };
  }
}
