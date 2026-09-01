class VoteRequest {
  final String destination;

  VoteRequest({
    required this.destination,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_destination': destination,
    };
  }
}
