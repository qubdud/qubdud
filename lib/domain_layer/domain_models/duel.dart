class Duel {
  final int id;
  final String beginDate;
  final String endDate;
  final String name;
  final DuelParticipant me;
  final DuelParticipant opponent;
  final String status;
  final String status2;
  final bool duelStart;

  Duel({
    required this.id,
    required this.beginDate,
    required this.endDate,
    required this.name,
    required this.me,
    required this.opponent,
    required this.status,
    required this.status2,
    required this.duelStart,
  });

  factory Duel.fromJson(Map<String, dynamic> json) => Duel(
    id: json['id'],
    beginDate: json['begin_date'],
    endDate: json['end_date'],
    name: json['name'],
    me: DuelParticipant.fromJson(json['me']),
    opponent: DuelParticipant.fromJson(json['opponent']),
    status: json['status'],
    status2: json['status_2'],
    duelStart: json['duel_start'],
  );
}

class DuelParticipant {
  final String firstName;
  final String lastName;
  final String name;
  final DuelDepartmentGroup departmentGroup;
  final DuelCountry country;
  final int pointsScored;
  final int points;
  final int? sumAnswersTime;
  final List<DuelAnswer> answers;

  DuelParticipant({
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.departmentGroup,
    required this.country,
    required this.pointsScored,
    required this.points,
    required this.sumAnswersTime,
    required this.answers,
  });

  factory DuelParticipant.fromJson(Map<String, dynamic> json) => DuelParticipant(
    firstName: json['first_name'],
    lastName: json['last_name'],
    name: json['name'],
    departmentGroup: DuelDepartmentGroup.fromJson(json['department_group']),
    country: DuelCountry.fromJson(json['country']),
    pointsScored: json['points_scored'],
    points: json['points'],
    sumAnswersTime: json['sum_answers_time'],
    answers: (json['answers'] as List)
        .map((e) => DuelAnswer.fromJson(e))
        .toList(),
  );
}

class DuelDepartmentGroup {
  final String id;
  final String name;
  final String code;
  final int color;

  DuelDepartmentGroup({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
  });

  factory DuelDepartmentGroup.fromJson(Map<String, dynamic> json) =>
      DuelDepartmentGroup(
        id: json['id'],
        name: json['name'],
        code: json['code'],
        color: json['color'],
      );
}

class DuelCountry {
  final String id;
  final String name;
  final String countryCode;

  DuelCountry({
    required this.id,
    required this.name,
    required this.countryCode,
  });

  factory DuelCountry.fromJson(Map<String, dynamic> json) => DuelCountry(
    id: json['id'],
    name: json['name'],
    countryCode: json['country_code'],
  );
}

class DuelAnswer {
  final String question;
  final int categoryId;
  final String category;
  final bool? isCorrectAnswer;
  final int number;
  final int numberByCategory;
  final int totalQuestions;
  final int totalQuestionsByCategory;
  final int total;

  DuelAnswer({
    required this.question,
    required this.categoryId,
    required this.category,
    required this.isCorrectAnswer,
    required this.number,
    required this.numberByCategory,
    required this.totalQuestions,
    required this.totalQuestionsByCategory,
    required this.total,
  });

  factory DuelAnswer.fromJson(Map<String, dynamic> json) => DuelAnswer(
    question: json['question'],
    categoryId: json['category_id'],
    category: json['category'],
    isCorrectAnswer: json['is_correct_answer'],
    number: json['number'],
    numberByCategory: json['number_by_category'],
    totalQuestions: json['total_questions'],
    totalQuestionsByCategory: json['total_questions_by_category'],
    total: json['total'],
  );
}

class DuelSummary {
  final int id;
  final String beginDate;
  final String endDate;
  final String name;
  final DuelSummaryParticipant me;
  final DuelSummaryParticipant opponent;
  final String status;
  final String status2;
  final bool duelStart;

  DuelSummary({
    required this.id,
    required this.beginDate,
    required this.endDate,
    required this.name,
    required this.me,
    required this.opponent,
    required this.status,
    required this.status2,
    required this.duelStart,
  });

  factory DuelSummary.fromJson(Map<String, dynamic> json) {
    return DuelSummary(
      id: json['id'],
      beginDate: json['begin_date'],
      endDate: json['end_date'],
      name: json['name'],
      me: DuelSummaryParticipant.fromJson(json['me']),
      opponent: DuelSummaryParticipant.fromJson(json['opponent']),
      status: json['status'],
      status2: json['status_2'],
      duelStart: json['duel_start'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'begin_date': beginDate,
      'end_date': endDate,
      'name': name,
      'me': me.toJson(),
      'opponent': opponent.toJson(),
      'status': status,
      'status_2': status2,
      'duel_start': duelStart,
    };
  }
}

class DuelSummaryParticipant {
  final String firstName;
  final String lastName;
  final String name;
  final DuelSummaryDepartmentGroup departmentGroup;
  final DuelSummaryCountry country;
  final int? pointsScored;
  final int? points;
  final int? sumAnswersTime;
  final List<DuelSummaryAnswer> answers;

  DuelSummaryParticipant({
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.departmentGroup,
    required this.country,
    this.pointsScored,
    this.points,
    this.sumAnswersTime,
    required this.answers,
  });

  factory DuelSummaryParticipant.fromJson(Map<String, dynamic> json) {
    return DuelSummaryParticipant(
      firstName: json['first_name'],
      lastName: json['last_name'],
      name: json['name'],
      departmentGroup: DuelSummaryDepartmentGroup.fromJson(json['department_group']),
      country: DuelSummaryCountry.fromJson(json['country']),
      pointsScored: json['points_scored'],
      points: json['points'],
      sumAnswersTime: json['sum_answers_time'],
      answers: (json['answers'] as List<dynamic>)
          .map((e) => DuelSummaryAnswer.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'name': name,
      'department_group': departmentGroup.toJson(),
      'country': country.toJson(),
      'points_scored': pointsScored,
      'points': points,
      'sum_answers_time': sumAnswersTime,
      'answers': answers.map((e) => e.toJson()).toList(),
    };
  }
}

class DuelSummaryDepartmentGroup {
  final String id;
  final String name;
  final String code;
  final int color;

  DuelSummaryDepartmentGroup({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
  });

  factory DuelSummaryDepartmentGroup.fromJson(Map<String, dynamic> json) {
    return DuelSummaryDepartmentGroup(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'color': color,
    };
  }
}

class DuelSummaryCountry {
  final String id;
  final String name;
  final String countryCode;

  DuelSummaryCountry({
    required this.id,
    required this.name,
    required this.countryCode,
  });

  factory DuelSummaryCountry.fromJson(Map<String, dynamic> json) {
    return DuelSummaryCountry(
      id: json['id'],
      name: json['name'],
      countryCode: json['country_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country_code': countryCode,
    };
  }
}

class DuelSummaryAnswer {
  final String question;
  final int categoryId;
  final String category;
  final bool? isCorrectAnswer;
  final int number;
  final int numberByCategory;
  final int totalQuestions;
  final int totalQuestionsByCategory;
  final int total;
  final String? myAnswer;
  final String? correctAnswer;

  DuelSummaryAnswer({
    required this.question,
    required this.categoryId,
    required this.category,
    this.isCorrectAnswer,
    required this.number,
    required this.numberByCategory,
    required this.totalQuestions,
    required this.totalQuestionsByCategory,
    required this.total,
    this.myAnswer,
    this.correctAnswer,
  });

  factory DuelSummaryAnswer.fromJson(Map<String, dynamic> json) {
    return DuelSummaryAnswer(
      question: json['question'],
      categoryId: json['category_id'],
      category: json['category'],
      isCorrectAnswer: json['is_correct_answer'],
      number: json['number'],
      numberByCategory: json['number_by_category'],
      totalQuestions: json['total_questions'],
      totalQuestionsByCategory: json['total_questions_by_category'],
      total: json['total'],
      myAnswer: json['my_answer'],
      correctAnswer: json['correct_answer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'category_id': categoryId,
      'category': category,
      'is_correct_answer': isCorrectAnswer,
      'number': number,
      'number_by_category': numberByCategory,
      'total_questions': totalQuestions,
      'total_questions_by_category': totalQuestionsByCategory,
      'total': total,
      'my_answer': myAnswer,
      'correct_answer': correctAnswer,
    };
  }
}
class DuelQuestion {
  final int id;
  final String question;
  final int categoryId;
  final String category;
  final int total;
  final int totalQuestionsByCategory;
  final int number;
  final int numberByCategory;
  final List<DuelQuestionAnswer> answers;

  DuelQuestion({
    required this.id,
    required this.question,
    required this.categoryId,
    required this.category,
    required this.total,
    required this.totalQuestionsByCategory,
    required this.number,
    required this.numberByCategory,
    required this.answers,
  });

  factory DuelQuestion.fromJson(Map<String, dynamic> json) {
    return DuelQuestion(
      id: json['id'],
      question: json['question'],
      categoryId: json['category_id'],
      category: json['category'],
      total: json['total'],
      totalQuestionsByCategory: json['total_questions_by_category'],
      number: json['number'],
      numberByCategory: json['number_by_category'],
      answers: (json['answers'] as List)
          .map((answer) => DuelQuestionAnswer.fromJson(answer))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'category_id': categoryId,
      'category': category,
      'total': total,
      'total_questions_by_category': totalQuestionsByCategory,
      'number': number,
      'number_by_category': numberByCategory,
      'answers': answers.map((answer) => answer.toJson()).toList(),
    };
  }
}

class DuelQuestionAnswer {
  final int id;
  final String answer;

  DuelQuestionAnswer({
    required this.id,
    required this.answer,
  });

  factory DuelQuestionAnswer.fromJson(Map<String, dynamic> json) {
    return DuelQuestionAnswer(
      id: json['id'],
      answer: json['answer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'answer': answer,
    };
  }
}

