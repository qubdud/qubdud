class Ranking {
  final List<RankingEntry> results;
  final List<RankingEntry> me;
  final RankingInfo ranking;

  Ranking({
    required this.results,
    required this.me,
    required this.ranking,
  });

  factory Ranking.fromJson(Map<String, dynamic> json) {
    return Ranking(
      results: (json['results'] as List<dynamic>)
          .map((e) => RankingEntry.fromJson(e))
          .toList(),
      me: (json['me'] as List<dynamic>?)
          ?.map((e) => RankingEntry.fromJson(e))
          .toList() ?? [],
      ranking: RankingInfo.fromJson(json['ranking']),
    );
  }
}

class RankingEntry {
  final int id;
  final String position;
  final String name;
  final int result;
  final bool star;
  final String countryCode;
  final String countryName;
  final String departmentGroup;

  RankingEntry({
    required this.id,
    required this.position,
    required this.name,
    required this.result,
    required this.star,
    this.countryCode = '',
    this.countryName = '',
    this.departmentGroup = '',
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      id: json['id'] ?? 0,
      position: json['position'] ?? '',
      name: json['name'] ?? '',
      result: json['result'] ?? 0,
      star: json['star'] ?? false,
      countryCode: json['country_code'] ?? '',
      countryName: json['country_name'] ?? '',
      departmentGroup: json['department_group'] ?? '',
    );
  }
}

class RankingInfo {
  final int id;
  final String name;
  final String type;
  final String key;
  final String description;
  final String start;
  final String end;
  final String lastUpdated;

  RankingInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.key,
    required this.description,
    required this.start,
    required this.end,
    required this.lastUpdated,
  });

  factory RankingInfo.fromJson(Map<String, dynamic> json) {
    return RankingInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      key: json['key'] ?? '',
      description: json['description'] ?? '',
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
    );
  }
}

class RankingOption {
  final String name;
  final String key;

  RankingOption({required this.name, required this.key});

  factory RankingOption.fromJson(Map<String, dynamic> json) {
    return RankingOption(
      name: json['name'] ?? '',
      key: json['ranking']?['key'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'key': key,
    };
  }
}


