class EditTeamRequest {
  final String type;
  final String color;

  EditTeamRequest({
    required this.type,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'color': color,
    };
  }
}
