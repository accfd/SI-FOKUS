import 'package:equatable/equatable.dart';

abstract class StudentRecommendationEvent extends Equatable {
  const StudentRecommendationEvent();

  @override
  List<Object?> get props => [];
}

class LoadStudentRecommendation extends StudentRecommendationEvent {
  final String studentId;
  final String materialId;

  const LoadStudentRecommendation({
    required this.studentId,
    required this.materialId,
  });

  @override
  List<Object?> get props => [studentId, materialId];
}
