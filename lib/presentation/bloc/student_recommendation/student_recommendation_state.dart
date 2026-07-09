import 'package:equatable/equatable.dart';
import '../../../../data/models/student_recommendation_model.dart';

abstract class StudentRecommendationState extends Equatable {
  const StudentRecommendationState();

  @override
  List<Object?> get props => [];
}

class StudentRecommendationInitial extends StudentRecommendationState {}

class StudentRecommendationLoading extends StudentRecommendationState {}

class StudentRecommendationLoaded extends StudentRecommendationState {
  final StudentRecommendationModel recommendation;

  const StudentRecommendationLoaded(this.recommendation);

  @override
  List<Object?> get props => [recommendation];
}

class StudentRecommendationError extends StudentRecommendationState {
  final String message;

  const StudentRecommendationError(this.message);

  @override
  List<Object?> get props => [message];
}

class StudentRecommendationEmpty extends StudentRecommendationState {
  const StudentRecommendationEmpty();
}
