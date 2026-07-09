class QuestionModel {
  final String questionId;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  QuestionModel({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });

  QuestionModel copyWith({
    String? questionId,
    String? questionText,
    List<String>? options,
    int? correctAnswerIndex,
  }) {
    return QuestionModel(
      questionId: questionId ?? this.questionId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
    );
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      questionId: json['questionId'] as String? ?? '',
      questionText: json['questionText'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
    };
  }
}
