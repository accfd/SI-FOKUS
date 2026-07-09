import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/assessment_model.dart';
import '../../../../data/models/question_model.dart';
import 'quick_check_event.dart';
import 'quick_check_state.dart';

class QuickCheckBloc extends Bloc<QuickCheckEvent, QuickCheckState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track state internally for submission
  AssessmentModel? _currentAssessment;
  String _currentStudentId = '';
  String _currentMaterialId = '';

  QuickCheckBloc() : super(QuickCheckInitial()) {
    on<LoadQuickCheck>(_onLoadQuickCheck);
    on<SubmitQuickCheck>(_onSubmitQuickCheck);
  }

  Future<void> _onLoadQuickCheck(
    LoadQuickCheck event,
    Emitter<QuickCheckState> emit,
  ) async {
    emit(QuickCheckLoading());
    try {
      _currentStudentId = event.studentId;
      _currentMaterialId = event.materialId;

      // ALWAYS return dummy data for Mock MVP because Firestore is not connected
      // if (event.studentId == 'dummy_student' || event.studentId.contains('mock')) {
        final isMainQuiz = event.assessmentType == 'quiz_utama';
        
        final dummyAssessment = AssessmentModel(
          assessmentId: isMainQuiz ? 'dummy_quiz_utama_1' : 'dummy_quiz_1',
          materialId: event.materialId,
          classId: 'dummy_class',
          type: event.assessmentType,
          durationMinutes: isMainQuiz ? 15 : 5,
          questions: isMainQuiz 
          ? [
              QuestionModel(
                questionId: 'q1',
                questionText: 'Manakah dari berikut ini urutan yang benar dari organ pencernaan manusia?',
                options: ['Mulut - Lambung - Usus Halus - Usus Besar', 'Mulut - Kerongkongan - Lambung - Usus Halus - Usus Besar', 'Mulut - Kerongkongan - Usus Halus - Lambung', 'Mulut - Usus Besar - Usus Halus - Lambung'],
                correctAnswerIndex: 1,
              ),
              QuestionModel(
                questionId: 'q2',
                questionText: 'Fungsi utama dari jonjot usus (vili) pada usus halus adalah...',
                options: ['Menghasilkan enzim pencernaan', 'Memperluas permukaan penyerapan', 'Membunuh bakteri patogen', 'Menyimpan makanan sementara'],
                correctAnswerIndex: 1,
              ),
              QuestionModel(
                questionId: 'q3',
                questionText: 'Bakteri E. coli di usus besar berperan dalam pembentukan vitamin...',
                options: ['Vitamin A', 'Vitamin C', 'Vitamin K', 'Vitamin D'],
                correctAnswerIndex: 2,
              ),
              QuestionModel(
                questionId: 'q4',
                questionText: 'Enzim pepsin di lambung berfungsi untuk memecah...',
                options: ['Lemak', 'Karbohidrat', 'Protein', 'Vitamin'],
                correctAnswerIndex: 2,
              ),
              QuestionModel(
                questionId: 'q5',
                questionText: 'Gerakan meremas-remas pada kerongkongan disebut gerakan...',
                options: ['Peristaltik', 'Mekanik', 'Kimiawi', 'Refleks'],
                correctAnswerIndex: 0,
              ),
            ]
          : [
            QuestionModel(
              questionId: 'q1',
              questionText: 'Apa fungsi utama enzim amilase dalam sistem pencernaan?',
              options: [
                'Memecah protein',
                'Memecah karbohidrat menjadi zat gula',
                'Menyerap air',
                'Menghancurkan bakteri'
              ],
              correctAnswerIndex: 1,
            ),
            QuestionModel(
              questionId: 'q2',
              questionText: 'Di bagian organ manakah pencernaan mekanik terjadi secara paling intensif?',
              options: ['Usus halus', 'Lambung', 'Mulut', 'Kerongkongan'],
              correctAnswerIndex: 2,
            ),
            QuestionModel(
              questionId: 'q3',
              questionText: 'Zat apa yang dihasilkan hati untuk membantu pencernaan lemak?',
              options: ['Cairan Empedu', 'Asam Klorida', 'Enzim Pepsin', 'Insulin'],
              correctAnswerIndex: 0,
            ),
          ],
        );

        _currentAssessment = dummyAssessment;
        emit(QuickCheckReady(
          assessment: dummyAssessment,
          questions: dummyAssessment.questions,
        ));
        return;
      // }

      // 1. Cek progress siswa untuk materi ini
      final progressSnapshot = await _firestore
          .collection('student_progress')
          .where('studentId', isEqualTo: event.studentId)
          .where('materialId', isEqualTo: event.materialId)
          .limit(1)
          .get();

      if (progressSnapshot.docs.isNotEmpty) {
        final progressData = progressSnapshot.docs.first.data();
        
        if (progressData['isQuickCheckPassed'] == true) {
          // Sudah lulus, arahkan ke success atau main quiz
          emit(const QuickCheckPassed(score: 3)); // Dummy full score if already passed
          return;
        }

        // Cek cooldown
        if (progressData['cooldownUntil'] != null) {
          DateTime cooldownTime = (progressData['cooldownUntil'] as Timestamp).toDate();
          if (DateTime.now().isBefore(cooldownTime)) {
            emit(QuickCheckCooldown(cooldownUntil: cooldownTime));
            return;
          }
        }
      }

      // 2. Jika tidak ada cooldown, muat soal Quick Check
      final assessmentSnapshot = await _firestore
          .collection('assessments')
          .where('materialId', isEqualTo: event.materialId)
          .where('type', isEqualTo: 'quick_check')
          .limit(1)
          .get();

      if (assessmentSnapshot.docs.isEmpty) {
        // Fallback: Dummy Data agar UI bisa dites walau Database kosong
        final dummyAssessment = AssessmentModel(
          assessmentId: 'dummy_quiz_1',
          materialId: event.materialId,
          classId: 'dummy_class',
          type: 'quick_check',
          durationMinutes: 5,
          questions: [
            QuestionModel(
              questionId: 'q1',
              questionText: 'Apa fungsi utama enzim amilase dalam sistem pencernaan?',
              options: [
                'Memecah protein',
                'Memecah karbohidrat menjadi zat gula',
                'Menyerap air',
                'Menghancurkan bakteri'
              ],
              correctAnswerIndex: 1,
            ),
            QuestionModel(
              questionId: 'q2',
              questionText: 'Di bagian organ manakah pencernaan mekanik terjadi secara paling intensif?',
              options: ['Usus halus', 'Lambung', 'Mulut', 'Kerongkongan'],
              correctAnswerIndex: 2,
            ),
            QuestionModel(
              questionId: 'q3',
              questionText: 'Zat apa yang dihasilkan hati untuk membantu pencernaan lemak?',
              options: ['Cairan Empedu', 'Asam Klorida', 'Enzim Pepsin', 'Insulin'],
              correctAnswerIndex: 0,
            ),
          ],
        );

        _currentAssessment = dummyAssessment;
        emit(QuickCheckReady(
          assessment: dummyAssessment,
          questions: dummyAssessment.questions,
        ));
        return;
      }

      final assessment = AssessmentModel.fromJson(
        assessmentSnapshot.docs.first.data()..['assessmentId'] = assessmentSnapshot.docs.first.id
      );
      _currentAssessment = assessment;

      emit(QuickCheckReady(
        assessment: assessment,
        questions: assessment.questions,
      ));
    } catch (e) {
      emit(QuickCheckError('Gagal memuat kuis: $e'));
    }
  }

  Future<void> _onSubmitQuickCheck(
    SubmitQuickCheck event,
    Emitter<QuickCheckState> emit,
  ) async {
    if (_currentAssessment == null) return;
    
    emit(QuickCheckLoading());
    try {
      int correctAnswers = 0;

      for (var question in _currentAssessment!.questions) {
        final answerIndex = event.answers[question.questionId];
        if (answerIndex != null && answerIndex == question.correctAnswerIndex) {
          correctAnswers++;
        }
      }

      // Bypass Firestore jika menggunakan akun dummy
      if (_currentStudentId == 'dummy_student' || _currentStudentId.contains('mock')) {
        // Threshold kelulusan: 60% benar
        final passingThreshold = (_currentAssessment!.questions.length * 0.6).ceil();
        if (correctAnswers >= passingThreshold) {
          emit(QuickCheckPassed(score: correctAnswers));
        } else {
          final cooldownEnd = DateTime.now().add(const Duration(minutes: 10));
          emit(QuickCheckFailed(score: correctAnswers, cooldownUntil: cooldownEnd));
        }
        return;
      }

      // Cari atau buat doc reference untuk progress
      final progressQuery = await _firestore
          .collection('student_progress')
          .where('studentId', isEqualTo: _currentStudentId)
          .where('materialId', isEqualTo: _currentMaterialId)
          .limit(1)
          .get();

      DocumentReference progressRef;
      if (progressQuery.docs.isNotEmpty) {
        progressRef = progressQuery.docs.first.reference;
      } else {
        progressRef = _firestore.collection('student_progress').doc();
      }

      if (correctAnswers >= 2) {
        // LULUS (Benar >= 2)
        await progressRef.set({
          'studentId': _currentStudentId,
          'materialId': _currentMaterialId,
          'isQuickCheckPassed': true,
          'completedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        emit(QuickCheckPassed(score: correctAnswers));
      } else {
        // GAGAL (Benar < 2) -> Cooldown 10 menit
        final cooldownEnd = DateTime.now().add(const Duration(minutes: 10));
        
        await progressRef.set({
          'studentId': _currentStudentId,
          'materialId': _currentMaterialId,
          'isQuickCheckPassed': false,
          'cooldownUntil': Timestamp.fromDate(cooldownEnd),
        }, SetOptions(merge: true));

        emit(QuickCheckFailed(score: correctAnswers, cooldownUntil: cooldownEnd));
      }
    } catch (e) {
      emit(QuickCheckError('Gagal mengirim kuis: $e'));
    }
  }
}
