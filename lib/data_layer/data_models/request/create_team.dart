class CreateTeamRequest {
  final String name;
  final String type;
  final String color;

  CreateTeamRequest({
    required this.name,
    required this.type,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'color': color,
    };
  }
}
