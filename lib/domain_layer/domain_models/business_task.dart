class BusinessTask {
  final String id;
  final String number;
  final int points;
  final String description;

  BusinessTask({
    required this.id,
    required this.number,
    required this.points,
    required this.description,
  });

  factory BusinessTask.fromJson(Map<String, dynamic> json) {
    return BusinessTask(
      id: json['id'],
      number: json['number'],
      points: json['points'],
      description: json['description'],
    );
  }

}