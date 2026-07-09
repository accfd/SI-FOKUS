import '../../../data/models/analytics_model.dart';

abstract class AnalyticsState {
  const AnalyticsState();
}

class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading();
}

class AnalyticsLoaded extends AnalyticsState {
  final ClassAnalyticsModel analytics;

  const AnalyticsLoaded(this.analytics);
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);
}
