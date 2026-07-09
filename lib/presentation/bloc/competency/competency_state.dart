import '../../../data/models/competency_model.dart';

abstract class CompetencyState {
  const CompetencyState();
}

class CompetencyInitial extends CompetencyState {
  const CompetencyInitial();
}

class CompetencyLoading extends CompetencyState {
  const CompetencyLoading();
}

class CompetencyDataLoaded extends CompetencyState {
  final CompetencyModel competency;

  const CompetencyDataLoaded(this.competency);
}

class CompetencyError extends CompetencyState {
  final String message;

  const CompetencyError(this.message);
}
