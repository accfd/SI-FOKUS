abstract class TalentEvent {
  const TalentEvent();
}

class FetchTalentRecommendations extends TalentEvent {
  final String teacherId;

  const FetchTalentRecommendations(this.teacherId);
}
