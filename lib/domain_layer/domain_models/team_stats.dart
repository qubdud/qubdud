class TeamDetailStat {
  final String name;
  final int points;

  TeamDetailStat({
    required this.name,
    required this.points,
  });

  factory TeamDetailStat.fromJson(Map<String, dynamic> json) {
    return TeamDetailStat(
      name: json['name'],
      points: (double.tryParse(json['points'].toString())??0.0).toInt(),
    );
  }
}

class TeamStatistics {
  final List<TeamDetailStat> detailStats;
  final int points;
  final int rank;

  TeamStatistics({
    required this.detailStats,
    required this.points,
    required this.rank,
  });

  factory TeamStatistics.fromJson(Map<String, dynamic> json) {
    return TeamStatistics(
      detailStats: (json['score_parts'] as List).map((item) => TeamDetailStat.fromJson(item)).toList(),
      points: json['score_total'],
      rank: json['rank']??0,
    );
  }
}
