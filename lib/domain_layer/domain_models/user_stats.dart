class UserDetailStat {
  final String name;
  final int points;

  UserDetailStat({
    required this.name,
    required this.points,
  });

  factory UserDetailStat.fromJson(Map<String, dynamic> json) {
    return UserDetailStat(
      name: json['name'],
      points: ((double.tryParse(json['points'].toString()))??0.0).toInt(),
    );
  }
}

class UserStatistics {
  final List<UserDetailStat> detailStats;
  final int points;
  final int rank;

  UserStatistics({
    required this.detailStats,
    required this.points,
    required this.rank,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      detailStats: (json['score_parts'] as List).map((item) => UserDetailStat.fromJson(item)).toList(),
      points: json['score_total'],
      rank: json['rank']??0,
    );
  }
}
