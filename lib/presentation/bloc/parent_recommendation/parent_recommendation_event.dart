import 'package:equatable/equatable.dart';

abstract class ParentRecommendationEvent extends Equatable {
  const ParentRecommendationEvent();

  @override
  List<Object?> get props => [];
}

class LoadParentRecommendations extends ParentRecommendationEvent {
  final String studentUid;

  const LoadParentRecommendations({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}
