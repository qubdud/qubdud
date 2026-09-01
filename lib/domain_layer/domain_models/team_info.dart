class TeamInfo {
  final String id;
  final String name;
  final String chatToken;
  final int points;
  final String ranking;
  final int camperType;
  final int camperColor;

  TeamInfo({
    required this.id,
    required this.name,
    required this.chatToken,
    required this.points,
    required this.ranking,
    required this.camperType,
    required this.camperColor,
  });

  factory TeamInfo.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'] as Map<String, dynamic>?; // Obsługa null dla vehicle
    final ranking = json['ranking'] as Map<String, dynamic>?; // Obsługa null dla ranking

    return TeamInfo(
      id: vehicle?['id'] ?? '', // Jeśli vehicle jest null, zwróci pusty string
      name: vehicle?['name'] ?? '', // Domyślna wartość, gdy name jest null
      chatToken: vehicle?['chat_token'] ?? 'public_no_team_chat', // Domyślna wartość, gdy name jest null
      points: vehicle?['points'] ?? 0, // Domyślna wartość 0 dla points
      ranking: ranking?['position'] ?? '', // Domyślnie 0, jeśli ranking jest null
      camperType: vehicle?['type_key'] ?? 0, // Domyślny typ pojazdu
      camperColor: vehicle?['color_key'] ?? 0, // Domyślny kolor pojazdu
    );
  }
}

class TeamMember {
  final String name;
  final String role;
  final String countryCode;
  final String department;
  final String departmentGroup;
  final int points;
  final int color;

  TeamMember({
    required this.name,
    required this.role,
    required this.countryCode,
    required this.department,
    required this.departmentGroup,
    required this.points,
    required this.color,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json, String departmentGroup, int color) {
    return TeamMember(
      role: json['role'],
      name: json['name'],
      countryCode: json['country_code'], // Klucz dopasowany do struktury JSON
      department: departmentGroup, // Przekazujemy grupę departamentową
      departmentGroup: departmentGroup,
      points: json['points'],
      color: color,
    );
  }
}

List<TeamMember> parseTeamMembers(List<Map<String, dynamic>> departmentGroups) {
  List<TeamMember> teamMembers = [];

  for (var group in departmentGroups) {
    String departmentGroup = group['name'];
    int color = group['color'];

    for (var passenger in group['passengers']) {
      teamMembers.add(TeamMember.fromJson(passenger, departmentGroup, color));
    }
  }

  return teamMembers;
}


class TeamStickers {
  final List<String> stickers;

  TeamStickers({
    required this.stickers,
  });

  factory TeamStickers.fromJson(Map<String, dynamic> json) {
    return TeamStickers(
      stickers: List<String>.from(json['data'] ?? []),
    );
  }
}
