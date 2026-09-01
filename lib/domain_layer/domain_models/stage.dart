class StageDescription {
  final String text;
  final String heading;

  StageDescription({
    required this.text,
    required this.heading,
  });

  factory StageDescription.fromJson(Map<String, dynamic> json) {
    return StageDescription(
      text: json['text'] ?? '',
      heading: json['heading'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'heading': heading,
    };
  }
}

class StageData {
  final int id;
  final String name;
  final int stageNumber;
  final String start;
  final String end;
  final String capital;
  final String area;
  final String population;
  final String gdp;
  final List<StageDescription> descriptions;

  StageData({
    required this.id,
    required this.name,
    required this.stageNumber,
    required this.start,
    required this.end,
    required this.capital,
    required this.area,
    required this.population,
    required this.gdp,
    required this.descriptions,
  });

  factory StageData.fromJson(Map<String, dynamic> json) {
    return StageData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      stageNumber: json['stage_number'] ?? 0,
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      capital: json['capital'] ?? '',
      area: json['area'] ?? '',
      population: json['population'] ?? '',
      gdp: json['gdp'] ?? '',
      descriptions: json['descriptions'] != null
          ? (json['descriptions'] as List)
          .map((desc) => StageDescription.fromJson(desc))
          .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stage_number': stageNumber,
      'start': start,
      'end': end,
      'capital': capital,
      'area': area,
      'population': population,
      'gdp': gdp,
      'descriptions': descriptions.map((desc) => desc.toJson()).toList(),
    };
  }
}