import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/talent_repository.dart';
import 'talent_event.dart';
import 'talent_state.dart';

class TalentBloc extends Bloc<TalentEvent, TalentState> {
  final TalentRepository talentRepository;

  TalentBloc({required this.talentRepository}) : super(const TalentInitial()) {
    on<FetchTalentRecommendations>(_onFetchTalentRecommendations);
  }

  Future<void> _onFetchTalentRecommendations(
    FetchTalentRecommendations event,
    Emitter<TalentState> emit,
  ) async {
    emit(const TalentLoading());
    try {
      final recommendations = await talentRepository.fetchTalentRecommendations(event.teacherId);
      emit(TalentLoaded(recommendations));
    } catch (e) {
      emit(TalentError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
