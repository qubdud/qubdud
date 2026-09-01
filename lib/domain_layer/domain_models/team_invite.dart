class TeamInvite {
  final String teamId;
  final String teamName;
  final int points;
  final int memberCount;
  final bool isInvitationSent;

  TeamInvite({
    required this.teamId,
    required this.teamName,
    required this.points,
    required this.memberCount,
    required this.isInvitationSent,
  });

  factory TeamInvite.fromJson(Map<String, dynamic> json) {
    return TeamInvite(
      teamId: json['id'],
      teamName: json['name'],
      points: json['team_score'],
      memberCount: json['members'],
      isInvitationSent: json['offer_sent'],
    );
  }
}
