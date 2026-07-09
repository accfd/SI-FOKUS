import 'package:equatable/equatable.dart';
import '../../../../data/models/digital_learning_profile_model.dart';

abstract class LearningProfileState extends Equatable {
  const LearningProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends LearningProfileState {}

class ProfileLoading extends LearningProfileState {}

class ProfileLoaded extends LearningProfileState {
  final DigitalLearningProfileModel profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends LearningProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
