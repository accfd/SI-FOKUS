import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProgressModel {
  final String studentId;
  final String materialId;
  final bool isReadingCompleted;
  final DateTime? readingCompletedAt;
  final bool isQuickCheckPassed;
  final DateTime? quickCheckPassedAt;
  final bool isQuizUtamaCompleted;
  final DateTime? cooldownUntil;
  final int totalAttempts;

  StudentProgressModel({
    required this.studentId,
    required this.materialId,
    this.isReadingCompleted = false,
    this.readingCompletedAt,
    this.isQuickCheckPassed = false,
    this.quickCheckPassedAt,
    this.isQuizUtamaCompleted = false,
    this.cooldownUntil,
    this.totalAttempts = 0,
  });

  StudentProgressModel copyWith({
    String? studentId,
    String? materialId,
    bool? isReadingCompleted,
    DateTime? readingCompletedAt,
    bool? isQuickCheckPassed,
    DateTime? quickCheckPassedAt,
    bool? isQuizUtamaCompleted,
    DateTime? cooldownUntil,
    int? totalAttempts,
  }) {
    return StudentProgressModel(
      studentId: studentId ?? this.studentId,
      materialId: materialId ?? this.materialId,
      isReadingCompleted: isReadingCompleted ?? this.isReadingCompleted,
      readingCompletedAt: readingCompletedAt ?? this.readingCompletedAt,
      isQuickCheckPassed: isQuickCheckPassed ?? this.isQuickCheckPassed,
      quickCheckPassedAt: quickCheckPassedAt ?? this.quickCheckPassedAt,
      isQuizUtamaCompleted: isQuizUtamaCompleted ?? this.isQuizUtamaCompleted,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
      totalAttempts: totalAttempts ?? this.totalAttempts,
    );
  }

  factory StudentProgressModel.fromJson(Map<String, dynamic> json) {
    return StudentProgressModel(
      studentId: json['studentId'] as String? ?? '',
      materialId: json['materialId'] as String? ?? '',
      isReadingCompleted: json['isReadingCompleted'] as bool? ?? false,
      readingCompletedAt: _parseDateTime(json['readingCompletedAt']),
      isQuickCheckPassed: json['isQuickCheckPassed'] as bool? ?? false,
      quickCheckPassedAt: _parseDateTime(json['quickCheckPassedAt']),
      isQuizUtamaCompleted: json['isQuizUtamaCompleted'] as bool? ?? false,
      cooldownUntil: _parseDateTime(json['cooldownUntil']),
      totalAttempts: json['totalAttempts'] as int? ?? 0,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'materialId': materialId,
      'isReadingCompleted': isReadingCompleted,
      'readingCompletedAt': readingCompletedAt?.toIso8601String(),
      'isQuickCheckPassed': isQuickCheckPassed,
      'quickCheckPassedAt': quickCheckPassedAt?.toIso8601String(),
      'isQuizUtamaCompleted': isQuizUtamaCompleted,
      'cooldownUntil': cooldownUntil?.toIso8601String(),
      'totalAttempts': totalAttempts,
    };
  }
}
