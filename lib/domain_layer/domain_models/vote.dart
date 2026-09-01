class VoteData {
  final bool userCanVote;
  final List<VoteOption> options;

  VoteData({required this.userCanVote, required this.options});

  factory VoteData.fromJson(Map<String, dynamic> json) {
    return VoteData(
      userCanVote: json['user_can_vote'] as bool,
      options: (json['options'] as List).map((item) => VoteOption.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_can_vote': userCanVote,
      'options': options.map((option) => option.toJson()).toList(),
    };
  }
}

class VoteOption {
  final String id;
  final String name;
  final String image;

  VoteOption({required this.id, required this.name, required this.image});

  factory VoteOption.fromJson(Map<String, dynamic> json) {
    return VoteOption(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }
}
