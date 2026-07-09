class TalentRecommendationModel {
  final String recommendationId;
  final String teacherId;
  final String studentId;
  final String studentName;
  final String recommendedField; // 'olimpiade' | 'akademik' | 'sains' | 'informatika'
  final double confidenceScore; // Range 0.0 - 1.0 (gauge representation)
  final String reasoning;

  TalentRecommendationModel({
    required this.recommendationId,
    required this.teacherId,
    required this.studentId,
    required this.studentName,
    required this.recommendedField,
    required this.confidenceScore,
    required this.reasoning,
  });

  factory TalentRecommendationModel.fromJson(Map<String, dynamic> json) {
    return TalentRecommendationModel(
      recommendationId: json['recommendationId'] as String? ?? '',
      teacherId: json['teacherId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      recommendedField: json['recommendedField'] as String? ?? 'sains',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendationId': recommendationId,
      'teacherId': teacherId,
      'studentId': studentId,
      'studentName': studentName,
      'recommendedField': recommendedField,
      'confidenceScore': confidenceScore,
      'reasoning': reasoning,
    };
  }
}
