import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_model.dart';

class QuestionBankModel {
  final String bankId;
  final String materialId;
  final String classId;
  final DateTime createdAt;
  final String createdBy; // Selalu "system_ai"
  final int totalQuestions;
  final List<QuestionModel> questions;

  QuestionBankModel({
    required this.bankId,
    required this.materialId,
    required this.classId,
    required this.createdAt,
    this.createdBy = 'system_ai',
    this.totalQuestions = 25,
    required this.questions,
  });

  factory QuestionBankModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['createdAt'] is Timestamp) {
      parsedDate = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      parsedDate = DateTime.parse(json['createdAt'] as String);
    } else {
      parsedDate = DateTime.now();
    }

    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    final questions = rawQuestions
        .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return QuestionBankModel(
      bankId: json['bankId'] as String? ?? '',
      materialId: json['materialId'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      createdAt: parsedDate,
      createdBy: json['createdBy'] as String? ?? 'system_ai',
      totalQuestions: json['totalQuestions'] as int? ?? 25,
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankId': bankId,
      'materialId': materialId,
      'classId': classId,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'totalQuestions': totalQuestions,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bankId': bankId,
      'materialId': materialId,
      'classId': classId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'totalQuestions': totalQuestions,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}
