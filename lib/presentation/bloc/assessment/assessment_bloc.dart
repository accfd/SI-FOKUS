import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/assessment_repository.dart';
import 'assessment_event.dart';
import 'assessment_state.dart';

class AssessmentBloc extends Bloc<AssessmentEvent, AssessmentState> {
  final AssessmentRepository assessmentRepository;

  AssessmentBloc({required this.assessmentRepository}) : super(const AssessmentInitial()) {
    on<FetchAssessmentByMaterial>(_onFetchAssessmentByMaterial);
    on<GenerateAssessmentRequested>(_onGenerateAssessmentRequested);
    on<UpdateAssessmentQuestions>(_onUpdateAssessmentQuestions);
    on<UpdateQuizConfiguration>(_onUpdateQuizConfiguration);
  }

  Future<void> _onFetchAssessmentByMaterial(
    FetchAssessmentByMaterial event,
    Emitter<AssessmentState> emit,
  ) async {
    emit(const AssessmentLoading());
    try {
      final assessment = await assessmentRepository.fetchAssessmentByMaterial(
        event.materialId,
        event.type,
      );
      if (assessment != null) {
        emit(AssessmentLoaded(assessment));
      } else {
        emit(const AssessmentInitial());
      }
    } catch (e) {
      emit(AssessmentError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onGenerateAssessmentRequested(
    GenerateAssessmentRequested event,
    Emitter<AssessmentState> emit,
  ) async {
    emit(const AssessmentLoading());
    try {
      final assessment = await assessmentRepository.generateAssessment(
        materialId: event.materialId,
        classId: event.classId,
        type: event.type,
        materialTitle: event.materialTitle,
        fileUrl: event.fileUrl,
      );
      emit(AssessmentLoaded(assessment));
    } catch (e) {
      emit(AssessmentError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateAssessmentQuestions(
    UpdateAssessmentQuestions event,
    Emitter<AssessmentState> emit,
  ) async {
    emit(const AssessmentLoading());
    try {
      await assessmentRepository.updateAssessmentQuestions(
        event.assessmentId,
        event.questions,
      );
      emit(const AssessmentSuccess('Asesmen kuis berhasil disimpan.'));
      add(FetchAssessmentByMaterial(materialId: event.materialId, type: event.type));
    } catch (e) {
      emit(AssessmentError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateQuizConfiguration(
    UpdateQuizConfiguration event,
    Emitter<AssessmentState> emit,
  ) async {
    emit(const AssessmentLoading());
    try {
      await assessmentRepository.updateQuizConfiguration(
        assessmentId: event.assessmentId,
        startDate: event.startDate,
        endDate: event.endDate,
        durationMinutes: event.durationMinutes,
        isPublished: event.isPublished,
      );
      emit(const AssessmentSuccess('Konfigurasi kuis berhasil diperbarui.'));
      add(FetchAssessmentByMaterial(materialId: event.materialId, type: event.type));
    } catch (e) {
      emit(AssessmentError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
