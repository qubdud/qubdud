class NotificationCounters {
  final int camperInvitationReceived;
  final int camperJoinRequestReceived;
  final int challenge;
  final int duel;
  final int postCommented;
  final int postLiked;

  NotificationCounters({
    required this.camperInvitationReceived,
    required this.camperJoinRequestReceived,
    required this.challenge,
    required this.duel,
    required this.postCommented,
    required this.postLiked,
  });

  factory NotificationCounters.fromJson(Map<String, dynamic> json) {
    return NotificationCounters(
      camperInvitationReceived: json['camper_invitation_received'] ?? 0,
      camperJoinRequestReceived: json['camper_join_request_received'] ?? 0,
      challenge: json['challenge'] ?? 0,
      duel: json['duel'] ?? 0,
      postCommented: json['post_commented'] ?? 0,
      postLiked: json['post_liked'] ?? 0,
    );
  }
}
