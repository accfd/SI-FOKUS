import 'package:equatable/equatable.dart';
import '../../../../data/models/assessment_model.dart';
import '../../../../data/models/question_model.dart';

abstract class QuickCheckState extends Equatable {
  const QuickCheckState();

  @override
  List<Object?> get props => [];
}

class QuickCheckInitial extends QuickCheckState {}

class QuickCheckLoading extends QuickCheckState {}

class QuickCheckReady extends QuickCheckState {
  final AssessmentModel assessment;
  final List<QuestionModel> questions;

  const QuickCheckReady({required this.assessment, required this.questions});

  @override
  List<Object?> get props => [assessment, questions];
}

class QuickCheckCooldown extends QuickCheckState {
  final DateTime cooldownUntil;

  const QuickCheckCooldown({required this.cooldownUntil});

  @override
  List<Object?> get props => [cooldownUntil];
}

class QuickCheckPassed extends QuickCheckState {
  final int score;

  const QuickCheckPassed({required this.score});

  @override
  List<Object?> get props => [score];
}

class QuickCheckFailed extends QuickCheckState {
  final int score;
  final DateTime cooldownUntil;

  const QuickCheckFailed({required this.score, required this.cooldownUntil});

  @override
  List<Object?> get props => [score, cooldownUntil];
}

class QuickCheckError extends QuickCheckState {
  final String message;

  const QuickCheckError(this.message);

  @override
  List<Object?> get props => [message];
}
