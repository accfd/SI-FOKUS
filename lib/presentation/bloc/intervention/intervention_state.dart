import '../../../data/models/intervention_model.dart';

abstract class InterventionState {
  const InterventionState();
}

class InterventionInitial extends InterventionState {
  const InterventionInitial();
}

class InterventionLoading extends InterventionState {
  const InterventionLoading();
}

class InterventionLoaded extends InterventionState {
  final InterventionModel intervention;

  const InterventionLoaded(this.intervention);
}

class InterventionError extends InterventionState {
  final String message;

  const InterventionError(this.message);
}

class NotificationSendSuccess extends InterventionState {
  final String studentName;

  const NotificationSendSuccess(this.studentName);
}
