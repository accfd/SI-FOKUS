import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/analytics_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository analyticsRepository;

  AnalyticsBloc({required this.analyticsRepository}) : super(const AnalyticsInitial()) {
    on<FetchClassAnalyticsHistory>(_onFetchClassAnalyticsHistory);
  }

  Future<void> _onFetchClassAnalyticsHistory(
    FetchClassAnalyticsHistory event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(const AnalyticsLoading());
    try {
      final analytics = await analyticsRepository.fetchClassAnalytics(event.classId);
      emit(AnalyticsLoaded(analytics));
    } catch (e) {
      emit(AnalyticsError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
