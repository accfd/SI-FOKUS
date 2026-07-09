abstract class CompetencyEvent {
  const CompetencyEvent();
}

class FetchClassCompetencyData extends CompetencyEvent {
  final String classId;

  const FetchClassCompetencyData(this.classId);
}
