import 'package:equatable/equatable.dart';

abstract class ParentRecommendationState extends Equatable {
  const ParentRecommendationState();

  @override
  List<Object?> get props => [];
}

class ParentRecommendationInitial extends ParentRecommendationState {
  const ParentRecommendationInitial();
}

class ParentRecommendationLoading extends ParentRecommendationState {
  const ParentRecommendationLoading();
}

class RecommendationModel extends Equatable {
  final String title;
  final String category; // e.g. "Matematika", "Biologi", "Kebiasaan Belajar"
  final String recommendationText;
  final String actionStep; // Langkah konkrit yang bisa dilakukan orang tua
  final String iconType; // e.g. "math", "biology", "time", "general"

  const RecommendationModel({
    required this.title,
    required this.category,
    required this.recommendationText,
    required this.actionStep,
    required this.iconType,
  });

  @override
  List<Object?> get props => [title, category, recommendationText, actionStep, iconType];
}

class ParentRecommendationLoaded extends ParentRecommendationState {
  final String childName;
  final List<RecommendationModel> recommendations;

  const ParentRecommendationLoaded({
    required this.childName,
    required this.recommendations,
  });

  @override
  List<Object?> get props => [childName, recommendations];
}

class ParentRecommendationError extends ParentRecommendationState {
  final String message;

  const ParentRecommendationError(this.message);

  @override
  List<Object?> get props => [message];
}
