import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/competency_repository.dart';
import 'competency_event.dart';
import 'competency_state.dart';

class CompetencyBloc extends Bloc<CompetencyEvent, CompetencyState> {
  final CompetencyRepository competencyRepository;

  CompetencyBloc({required this.competencyRepository}) : super(const CompetencyInitial()) {
    on<FetchClassCompetencyData>(_onFetchClassCompetencyData);
  }

  Future<void> _onFetchClassCompetencyData(
    FetchClassCompetencyData event,
    Emitter<CompetencyState> emit,
  ) async {
    emit(const CompetencyLoading());
    try {
      final competency = await competencyRepository.fetchClassCompetency(event.classId);
      emit(CompetencyDataLoaded(competency));
    } catch (e) {
      emit(CompetencyError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
