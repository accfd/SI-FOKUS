class IndividualInterventionModel {
  final String studentId;
  final String studentName;
  final String message;

  IndividualInterventionModel({
    required this.studentId,
    required this.studentName,
    required this.message,
  });

  factory IndividualInterventionModel.fromJson(Map<String, dynamic> json) {
    return IndividualInterventionModel(
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'message': message,
    };
  }
}

class InterventionModel {
  final String interventionId;
  final String classId;
  final String materialId;
  final String summaryAlert;
  final List<String> recommendations;
  final List<IndividualInterventionModel> individualInterventions;

  InterventionModel({
    required this.interventionId,
    required this.classId,
    required this.materialId,
    required this.summaryAlert,
    required this.recommendations,
    required this.individualInterventions,
  });

  factory InterventionModel.fromJson(Map<String, dynamic> json) {
    final rawRecs = json['recommendations'] as List<dynamic>? ?? const [];
    final recommendations = rawRecs.map((e) => e.toString()).toList();

    final rawIndivs = json['individualInterventions'] as List<dynamic>? ?? const [];
    final individualInterventions = rawIndivs
        .map((e) => IndividualInterventionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return InterventionModel(
      interventionId: json['interventionId'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      materialId: json['materialId'] as String? ?? '',
      summaryAlert: json['summaryAlert'] as String? ?? '',
      recommendations: recommendations,
      individualInterventions: individualInterventions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interventionId': interventionId,
      'classId': classId,
      'materialId': materialId,
      'summaryAlert': summaryAlert,
      'recommendations': recommendations,
      'individualInterventions': individualInterventions.map((e) => e.toJson()).toList(),
    };
  }
}
