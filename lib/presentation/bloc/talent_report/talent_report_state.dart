import 'package:equatable/equatable.dart';

abstract class TalentReportState extends Equatable {
  const TalentReportState();

  @override
  List<Object?> get props => [];
}

class TalentReportInitial extends TalentReportState {
  const TalentReportInitial();
}

class TalentReportLoading extends TalentReportState {
  const TalentReportLoading();
}

class TalentRecommendationModel extends Equatable {
  final String studentId;
  final String recommendedField; // e.g. "Sains / Biologi", "Matematika", "Informatika"
  final double confidenceScore; // 0.0 to 100.0
  final String reasoning; // Analisis naratif yang hangat dan informatif
  final List<String> recommendedCompetitions; // Daftar lomba / olimpiade yang disarankan
  final List<String> supportSteps; // Langkah pendampingan di rumah

  const TalentRecommendationModel({
    required this.studentId,
    required this.recommendedField,
    required this.confidenceScore,
    required this.reasoning,
    required this.recommendedCompetitions,
    required this.supportSteps,
  });

  @override
  List<Object?> get props => [
        studentId,
        recommendedField,
        confidenceScore,
        reasoning,
        recommendedCompetitions,
        supportSteps,
      ];
}

class TalentReportLoaded extends TalentReportState {
  final String childName;
  final TalentRecommendationModel talentRecommendation;

  const TalentReportLoaded({
    required this.childName,
    required this.talentRecommendation,
  });

  @override
  List<Object?> get props => [childName, talentRecommendation];
}

class TalentReportError extends TalentReportState {
  final String message;

  const TalentReportError(this.message);

  @override
  List<Object?> get props => [message];
}
