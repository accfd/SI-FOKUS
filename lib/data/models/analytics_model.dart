class QuizTrendPoint {
  final String quizName;
  final double averageScore;

  QuizTrendPoint({
    required this.quizName,
    required this.averageScore,
  });

  factory QuizTrendPoint.fromJson(Map<String, dynamic> json) {
    return QuizTrendPoint(
      quizName: json['quizName'] as String? ?? '',
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizName': quizName,
      'averageScore': averageScore,
    };
  }
}

class ModuleReadingStat {
  final String moduleTitle;
  final double avgReadingMinutes;
  final double avgQuizScore;

  ModuleReadingStat({
    required this.moduleTitle,
    required this.avgReadingMinutes,
    required this.avgQuizScore,
  });

  factory ModuleReadingStat.fromJson(Map<String, dynamic> json) {
    return ModuleReadingStat(
      moduleTitle: json['moduleTitle'] as String? ?? '',
      avgReadingMinutes: (json['avgReadingMinutes'] as num?)?.toDouble() ?? 0.0,
      avgQuizScore: (json['avgQuizScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleTitle': moduleTitle,
      'avgReadingMinutes': avgReadingMinutes,
      'avgQuizScore': avgQuizScore,
    };
  }
}

class StudentAnalyticsSummary {
  final String studentId;
  final String studentName;
  final double avgQuizScore;
  final int completedModulesCount;

  StudentAnalyticsSummary({
    required this.studentId,
    required this.studentName,
    required this.avgQuizScore,
    required this.completedModulesCount,
  });

  factory StudentAnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return StudentAnalyticsSummary(
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      avgQuizScore: (json['avgQuizScore'] as num?)?.toDouble() ?? 0.0,
      completedModulesCount: json['completedModulesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'avgQuizScore': avgQuizScore,
      'completedModulesCount': completedModulesCount,
    };
  }
}

class ClassAnalyticsModel {
  final String classId;
  final List<QuizTrendPoint> quizTrends;
  final List<ModuleReadingStat> readingStats;
  final List<StudentAnalyticsSummary> studentSummaries;

  ClassAnalyticsModel({
    required this.classId,
    required this.quizTrends,
    required this.readingStats,
    required this.studentSummaries,
  });

  factory ClassAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final rawTrends = json['quizTrends'] as List<dynamic>? ?? const [];
    final quizTrends = rawTrends.map((e) => QuizTrendPoint.fromJson(e as Map<String, dynamic>)).toList();

    final rawStats = json['readingStats'] as List<dynamic>? ?? const [];
    final readingStats = rawStats.map((e) => ModuleReadingStat.fromJson(e as Map<String, dynamic>)).toList();

    final rawStudents = json['studentSummaries'] as List<dynamic>? ?? const [];
    final studentSummaries = rawStudents
        .map((e) => StudentAnalyticsSummary.fromJson(e as Map<String, dynamic>))
        .toList();

    return ClassAnalyticsModel(
      classId: json['classId'] as String? ?? '',
      quizTrends: quizTrends,
      readingStats: readingStats,
      studentSummaries: studentSummaries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'quizTrends': quizTrends.map((e) => e.toJson()).toList(),
      'readingStats': readingStats.map((e) => e.toJson()).toList(),
      'studentSummaries': studentSummaries.map((e) => e.toJson()).toList(),
    };
  }
}
