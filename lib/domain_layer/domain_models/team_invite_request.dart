class TeamInviteRequest {
  final String invitationId;
  final String teamId;
  final String teamName;
  final String date;
  final int points;
  final int memberCount;

  TeamInviteRequest({
    required this.invitationId,
    required this.teamId,
    required this.teamName,
    required this.date,
    required this.points,
    required this.memberCount,
  });

  factory TeamInviteRequest.fromJson(Map<String, dynamic> json) {
    return TeamInviteRequest(
      invitationId: json['id'],
      teamId: json['team_id']??'',
      teamName: json['team_name'],
      date: json['received_date'],
      points: json['team_score'],
      memberCount: json['members'],
    );
  }
}
