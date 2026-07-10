import 'package:flutter_bloc/flutter_bloc.dart';

import 'learning_report_event.dart';
import 'learning_report_state.dart';

class LearningReportBloc
    extends Bloc<LearningReportEvent, LearningReportState> {
  LearningReportBloc() : super(const LearningReportInitial()) {
    on<LoadLearningReport>(_onLoadLearningReport);
  }

  Future<void> _onLoadLearningReport(
    LoadLearningReport event,
    Emitter<LearningReportState> emit,
  ) async {
    emit(const LearningReportLoading());

    try {
      // ── DUMMY DATA untuk demo MVP ──
      // Pada production, data ini ditarik dari Firestore collections:
      //   - /assessments (soal kuis)
      //   - /student_progress (hasil pengerjaan)
      //   - /activities (riwayat aktivitas)

      final now = DateTime.now();

      final dummyQuizHistory = [
        QuizRecord(
          materialTitle: 'Biologi: Sistem Pencernaan',
          type: 'quick_check',
          score: 3,
          totalQuestions: 3,
          passed: true,
          date: now.subtract(const Duration(days: 1)),
        ),
        QuizRecord(
          materialTitle: 'Biologi: Sistem Pencernaan',
          type: 'quiz_utama',
          score: 8,
          totalQuestions: 10,
          passed: true,
          date: now.subtract(const Duration(days: 1)),
        ),
        QuizRecord(
          materialTitle: 'Sejarah: Perang Dunia II',
          type: 'quick_check',
          score: 1,
          totalQuestions: 3,
          passed: false,
          date: now.subtract(const Duration(days: 3)),
        ),
        QuizRecord(
          materialTitle: 'Sejarah: Perang Dunia II',
          type: 'quick_check',
          score: 2,
          totalQuestions: 3,
          passed: true,
          date: now.subtract(const Duration(days: 2)),
        ),
        QuizRecord(
          materialTitle: 'Sejarah: Perang Dunia II',
          type: 'quiz_utama',
          score: 7,
          totalQuestions: 10,
          passed: true,
          date: now.subtract(const Duration(days: 2)),
        ),
        QuizRecord(
          materialTitle: 'Matematika: Aljabar Linear',
          type: 'quick_check',
          score: 2,
          totalQuestions: 3,
          passed: true,
          date: now.subtract(const Duration(days: 5)),
        ),
        QuizRecord(
          materialTitle: 'Matematika: Aljabar Linear',
          type: 'quiz_utama',
          score: 6,
          totalQuestions: 10,
          passed: false,
          date: now.subtract(const Duration(days: 4)),
        ),
        QuizRecord(
          materialTitle: 'Fisika: Hukum Newton',
          type: 'quick_check',
          score: 3,
          totalQuestions: 3,
          passed: true,
          date: now.subtract(const Duration(days: 7)),
        ),
        QuizRecord(
          materialTitle: 'Fisika: Hukum Newton',
          type: 'quiz_utama',
          score: 9,
          totalQuestions: 10,
          passed: true,
          date: now.subtract(const Duration(days: 6)),
        ),
      ];

      // Hanya ambil Kuis Utama untuk grafik tren (lebih bermakna)
      final mainQuizzes = dummyQuizHistory
          .where((q) => q.type == 'quiz_utama')
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final trendData = mainQuizzes
          .map((q) => TrendPoint(
                date: q.date,
                scorePercent: q.percentage,
                label: q.materialTitle.split(':').first.trim(),
              ))
          .toList();

      // Statistik ringkas
      final totalQuizzes = dummyQuizHistory.length;
      final totalPassed = dummyQuizHistory.where((q) => q.passed).length;
      final avgScore = dummyQuizHistory.isNotEmpty
          ? dummyQuizHistory.fold<double>(
                  0, (acc, q) => acc + q.percentage) /
              totalQuizzes
          : 0.0;

      // Urutkan riwayat dari terbaru
      dummyQuizHistory.sort((a, b) => b.date.compareTo(a.date));

      emit(LearningReportLoaded(
        childName: 'Ahmad Fauzi',
        totalQuizzes: totalQuizzes,
        totalPassed: totalPassed,
        averageScore: avgScore,
        quizHistory: dummyQuizHistory,
        trendData: trendData,
      ));
    } catch (e) {
      emit(LearningReportError('Gagal memuat laporan belajar: $e'));
    }
  }
}
