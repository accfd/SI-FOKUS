abstract class AnalyticsEvent {
  const AnalyticsEvent();
}

class FetchClassAnalyticsHistory extends AnalyticsEvent {
  final String classId;

  const FetchClassAnalyticsHistory(this.classId);
}
