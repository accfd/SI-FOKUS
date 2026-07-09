import '../../../data/models/talent_recommendation_model.dart';

abstract class TalentState {
  const TalentState();
}

class TalentInitial extends TalentState {
  const TalentInitial();
}

class TalentLoading extends TalentState {
  const TalentLoading();
}

class TalentLoaded extends TalentState {
  final List<TalentRecommendationModel> recommendations;

  const TalentLoaded(this.recommendations);
}

class TalentError extends TalentState {
  final String message;

  const TalentError(this.message);
}
