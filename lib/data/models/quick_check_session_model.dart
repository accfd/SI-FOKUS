import 'package:cloud_firestore/cloud_firestore.dart';

class QuickCheckSessionModel {
  final String sessionId;
  final String studentId;
  final String materialId;
  final String bankId;
  final List<String> selectedQuestionIds;
  final Map<String, int> answers; // questionId -> selectedAnswerIndex
  final int? score;
  final bool? isPassed;
  final int attemptNumber;
  final DateTime startedAt;
  final DateTime? submittedAt;

  QuickCheckSessionModel({
    required this.sessionId,
    required this.studentId,
    required this.materialId,
    required this.bankId,
    required this.selectedQuestionIds,
    this.answers = const {},
    this.score,
    this.isPassed,
    this.attemptNumber = 1,
    required this.startedAt,
    this.submittedAt,
  });

  QuickCheckSessionModel copyWith({
    String? sessionId,
    String? studentId,
    String? materialId,
    String? bankId,
    List<String>? selectedQuestionIds,
    Map<String, int>? answers,
    int? score,
    bool? isPassed,
    int? attemptNumber,
    DateTime? startedAt,
    DateTime? submittedAt,
  }) {
    return QuickCheckSessionModel(
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      materialId: materialId ?? this.materialId,
      bankId: bankId ?? this.bankId,
      selectedQuestionIds: selectedQuestionIds ?? this.selectedQuestionIds,
      answers: answers ?? this.answers,
      score: score ?? this.score,
      isPassed: isPassed ?? this.isPassed,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  factory QuickCheckSessionModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedStart;
    if (json['startedAt'] is Timestamp) {
      parsedStart = (json['startedAt'] as Timestamp).toDate();
    } else if (json['startedAt'] is String) {
      parsedStart = DateTime.parse(json['startedAt'] as String);
    } else {
      parsedStart = DateTime.now();
    }

    DateTime? parsedSubmit;
    if (json['submittedAt'] is Timestamp) {
      parsedSubmit = (json['submittedAt'] as Timestamp).toDate();
    } else if (json['submittedAt'] is String) {
      parsedSubmit = DateTime.tryParse(json['submittedAt'] as String);
    }

    // Parse answers map
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? {};
    final answers = rawAnswers.map((k, v) => MapEntry(k, v as int));

    // Parse selectedQuestionIds
    final rawIds = json['selectedQuestionIds'] as List<dynamic>? ?? [];
    final ids = rawIds.map((e) => e.toString()).toList();

    return QuickCheckSessionModel(
      sessionId: json['sessionId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      materialId: json['materialId'] as String? ?? '',
      bankId: json['bankId'] as String? ?? '',
      selectedQuestionIds: ids,
      answers: answers,
      score: json['score'] as int?,
      isPassed: json['isPassed'] as bool?,
      attemptNumber: json['attemptNumber'] as int? ?? 1,
      startedAt: parsedStart,
      submittedAt: parsedSubmit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'studentId': studentId,
      'materialId': materialId,
      'bankId': bankId,
      'selectedQuestionIds': selectedQuestionIds,
      'answers': answers,
      'score': score,
      'isPassed': isPassed,
      'attemptNumber': attemptNumber,
      'startedAt': startedAt.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
    };
  }
}
