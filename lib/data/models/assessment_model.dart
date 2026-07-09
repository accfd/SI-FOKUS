import 'question_model.dart';

class AssessmentModel {
  final String assessmentId;
  final String materialId;
  final String classId;
  final String type; // 'quick_check' | 'quiz_utama'
  final List<QuestionModel> questions;
  final DateTime? startDate;
  final DateTime? endDate;
  final int durationMinutes;
  final bool isPublished;

  AssessmentModel({
    required this.assessmentId,
    required this.materialId,
    required this.classId,
    required this.type,
    this.questions = const [],
    this.startDate,
    this.endDate,
    this.durationMinutes = 60,
    this.isPublished = false,
  });

  AssessmentModel copyWith({
    String? assessmentId,
    String? materialId,
    String? classId,
    String? type,
    List<QuestionModel>? questions,
    DateTime? startDate,
    DateTime? endDate,
    int? durationMinutes,
    bool? isPublished,
  }) {
    return AssessmentModel(
      assessmentId: assessmentId ?? this.assessmentId,
      materialId: materialId ?? this.materialId,
      classId: classId ?? this.classId,
      type: type ?? this.type,
      questions: questions ?? this.questions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      assessmentId: json['assessmentId'] as String? ?? '',
      materialId: json['materialId'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      type: json['type'] as String? ?? 'quick_check',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'] as String) : null,
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      isPublished: json['isPublished'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assessmentId': assessmentId,
      'materialId': materialId,
      'classId': classId,
      'type': type,
      'questions': questions.map((e) => e.toJson()).toList(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'isPublished': isPublished,
    };
  }
}
