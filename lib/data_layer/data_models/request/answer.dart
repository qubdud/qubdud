class AnswerRequest {
  final int answerId;
  final int questionId;

  AnswerRequest({
    required this.answerId,
    required this.questionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'answer_id': answerId,
      'question_id': questionId,
    };
  }
}
