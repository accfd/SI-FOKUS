import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/student_recommendation_model.dart';
import 'student_recommendation_event.dart';
import 'student_recommendation_state.dart';

class StudentRecommendationBloc
    extends Bloc<StudentRecommendationEvent, StudentRecommendationState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StudentRecommendationBloc() : super(StudentRecommendationInitial()) {
    on<LoadStudentRecommendation>(_onLoadStudentRecommendation);
  }

  Future<void> _onLoadStudentRecommendation(
    LoadStudentRecommendation event,
    Emitter<StudentRecommendationState> emit,
  ) async {
    emit(StudentRecommendationLoading());
    try {
      final snapshot = await _firestore
          .collection('student_recommendations')
          .where('studentId', isEqualTo: event.studentId)
          .where('materialId', isEqualTo: event.materialId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['recommendationId'] = snapshot.docs.first.id;
        final recommendation = StudentRecommendationModel.fromJson(data);
        emit(StudentRecommendationLoaded(recommendation));
      } else {
        emit(const StudentRecommendationEmpty());
      }
    } catch (e) {
      emit(StudentRecommendationError(
          'Gagal memuat rekomendasi personal: $e'));
    }
  }
}
