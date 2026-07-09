class StudentRecommendationModel {
  final String recommendationId;
  final String studentId;
  final String materialId;
  final String classId;
  final List<String> reLearnTopics;
  final List<String> weaknesses;
  final List<String> strengths;
  final String recommendedMethod;
  final List<String> nextGoals;

  StudentRecommendationModel({
    required this.recommendationId,
    required this.studentId,
    required this.materialId,
    required this.classId,
    this.reLearnTopics = const [],
    this.weaknesses = const [],
    this.strengths = const [],
    required this.recommendedMethod,
    this.nextGoals = const [],
  });

  factory StudentRecommendationModel.fromJson(Map<String, dynamic> json) {
    return StudentRecommendationModel(
      recommendationId: json['recommendationId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      materialId: json['materialId'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      reLearnTopics: (json['reLearnTopics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      strengths: (json['strengths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      recommendedMethod: json['recommendedMethod'] as String? ?? '',
      nextGoals: (json['nextGoals'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendationId': recommendationId,
      'studentId': studentId,
      'materialId': materialId,
      'classId': classId,
      'reLearnTopics': reLearnTopics,
      'weaknesses': weaknesses,
      'strengths': strengths,
      'recommendedMethod': recommendedMethod,
      'nextGoals': nextGoals,
    };
  }
}
