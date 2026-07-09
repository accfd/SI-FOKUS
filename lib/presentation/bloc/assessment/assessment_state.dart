import '../../../data/models/assessment_model.dart';

abstract class AssessmentState {
  const AssessmentState();
}

class AssessmentInitial extends AssessmentState {
  const AssessmentInitial();
}

class AssessmentLoading extends AssessmentState {
  const AssessmentLoading();
}

class AssessmentSuccess extends AssessmentState {
  final String message;

  const AssessmentSuccess(this.message);
}

class AssessmentError extends AssessmentState {
  final String message;

  const AssessmentError(this.message);
}

class AssessmentLoaded extends AssessmentState {
  final AssessmentModel assessment;

  const AssessmentLoaded(this.assessment);
}
