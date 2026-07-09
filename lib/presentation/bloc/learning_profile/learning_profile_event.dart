import 'package:equatable/equatable.dart';

abstract class LearningProfileEvent extends Equatable {
  const LearningProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadDigitalLearningProfile extends LearningProfileEvent {
  final String studentId;

  const LoadDigitalLearningProfile(this.studentId);

  @override
  List<Object?> get props => [studentId];
}
