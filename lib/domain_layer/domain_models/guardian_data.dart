class GuardianInstitutionData {
  final List<GuardianInstitution> institutions;
  final List<GuardianAdvisor> advisors;

  GuardianInstitutionData({
    required this.institutions,
    required this.advisors,
  });

  factory GuardianInstitutionData.fromJson(Map<String, dynamic> json) {
    return GuardianInstitutionData(
      institutions: (json['institution']['list'] as List).map((e) => GuardianInstitution.fromJson(e)).toList(),
      advisors: (json['institution']['advisor_list'] as List).map((e) => GuardianAdvisor.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institution': {
        'list': institutions.map((e) => e.toJson()).toList(),
        'advisor_list': advisors.map((e) => e.toJson()).toList(),
      },
    };
  }
}

class GuardianInstitution {
  final String id;
  final String name;
  final int points;
  final List<GuardianUser> users;

  GuardianInstitution({
    required this.id,
    required this.name,
    required this.points,
    required this.users,
  });

  factory GuardianInstitution.fromJson(Map<String, dynamic> json) {
    return GuardianInstitution(
      id: json['id'],
      name: json['name'],
      points: json['points'],
      users: (json['users'] as List).map((e) => GuardianUser.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points': points,
      'users': users.map((e) => e.toJson()).toList(),
    };
  }
}

class GuardianUser {
  final GuardianAvatar avatar;
  final String name;
  final int soldCartCount;
  final int businessCardCount;
  final int retailCardCount;
  final int salesPoints;
  final int duelPoints;
  final int elearningPoints;
  final dynamic currentElearningDone;
  final bool currentDuelDone;
  final int sumPoints;

  GuardianUser({
    required this.avatar,
    required this.name,
    required this.soldCartCount,
    required this.businessCardCount,
    required this.retailCardCount,
    required this.salesPoints,
    required this.duelPoints,
    required this.elearningPoints,
    this.currentElearningDone,
    required this.currentDuelDone,
    required this.sumPoints,
  });

  factory GuardianUser.fromJson(Map<String, dynamic> json) {
    return GuardianUser(
      avatar: GuardianAvatar.fromJson(json['avatar']),
      name: json['name'],
      soldCartCount: json['sold_cart_count'],
      businessCardCount: json['business_card_count'],
      retailCardCount: json['retail_card_count'],
      salesPoints: json['sales_points'],
      duelPoints: json['duel_points'],
      elearningPoints: json['elearning_points'],
      currentElearningDone: json['current_elearning_done'],
      currentDuelDone: json['current_duel_done'],
      sumPoints: json['sum_points'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatar': avatar.toJson(),
      'name': name,
      'sold_cart_count': soldCartCount,
      'business_card_count': businessCardCount,
      'retail_card_count': retailCardCount,
      'sales_points': salesPoints,
      'duel_points': duelPoints,
      'elearning_points': elearningPoints,
      'current_elearning_done': currentElearningDone,
      'current_duel_done': currentDuelDone,
      'sum_points': sumPoints,
    };
  }
}

class GuardianAvatar {
  final String id;
  final String name;

  GuardianAvatar({
    required this.id,
    required this.name,
  });

  factory GuardianAvatar.fromJson(Map<String, dynamic> json) {
    return GuardianAvatar(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class GuardianAdvisor {
  final String name;
  final String institution;
  final int points;

  GuardianAdvisor({
    required this.name,
    required this.institution,
    required this.points,
  });

  factory GuardianAdvisor.fromJson(Map<String, dynamic> json) {
    return GuardianAdvisor(
      name: json['name'],
      institution: json['institution'],
      points: json['points'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'institution': institution,
      'points': points,
    };
  }
}
