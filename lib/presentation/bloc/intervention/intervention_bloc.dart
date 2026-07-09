import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/intervention_repository.dart';
import 'intervention_event.dart';
import 'intervention_state.dart';

class InterventionBloc extends Bloc<InterventionEvent, InterventionState> {
  final InterventionRepository interventionRepository;

  InterventionBloc({required this.interventionRepository}) : super(const InterventionInitial()) {
    on<FetchInterventionDataEvent>(_onFetchInterventionData);
    on<SendNotificationRequested>(_onSendNotificationRequested);
  }

  Future<void> _onFetchInterventionData(
    FetchInterventionDataEvent event,
    Emitter<InterventionState> emit,
  ) async {
    emit(const InterventionLoading());
    try {
      final intervention = await interventionRepository.fetchInterventionData(
        event.classId,
        event.materialId,
      );
      emit(InterventionLoaded(intervention));
    } catch (e) {
      emit(InterventionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSendNotificationRequested(
    SendNotificationRequested event,
    Emitter<InterventionState> emit,
  ) async {
    final currentState = state;
    if (currentState is InterventionLoaded) {
      try {
        await interventionRepository.sendQuickNotification(
          studentId: event.studentId,
          message: event.message,
        );
        emit(NotificationSendSuccess(event.studentName));
        // Kembalikan ke state loaded agar data tidak hilang dari layar
        emit(InterventionLoaded(currentState.intervention));
      } catch (e) {
        emit(InterventionError(e.toString().replaceAll('Exception: ', '')));
      }
    }
  }
}
