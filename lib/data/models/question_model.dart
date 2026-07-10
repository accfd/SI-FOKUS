class QuestionModel {
  final String questionId;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String topicTag; // Topik materi yang dicakup soal ini
  final String type; // 'pilihan_ganda' | 'majemuk_kompleks' | 'isian_singkat'
  final List<int>? correctAnswers; // Untuk majemuk kompleks (misal: [1, 0, 1])
  final String? correctAnswerText; // Untuk isian singkat

  QuestionModel({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.topicTag = '',
    this.type = 'pilihan_ganda',
    this.correctAnswers,
    this.correctAnswerText,
  });

  QuestionModel copyWith({
    String? questionId,
    String? questionText,
    List<String>? options,
    int? correctAnswerIndex,
    String? topicTag,
    String? type,
    List<int>? correctAnswers,
    String? correctAnswerText,
  }) {
    return QuestionModel(
      questionId: questionId ?? this.questionId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      topicTag: topicTag ?? this.topicTag,
      type: type ?? this.type,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      correctAnswerText: correctAnswerText ?? this.correctAnswerText,
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
      topicTag: json['topicTag'] as String? ?? '',
      type: json['type'] as String? ?? 'pilihan_ganda',
      correctAnswers: (json['correctAnswers'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      correctAnswerText: json['correctAnswerText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'topicTag': topicTag,
      'type': type,
      'correctAnswers': correctAnswers,
      'correctAnswerText': correctAnswerText,
    };
  }
}
