import 'package:equatable/equatable.dart';

abstract class LearningReportState extends Equatable {
  const LearningReportState();

  @override
  List<Object?> get props => [];
}

class LearningReportInitial extends LearningReportState {
  const LearningReportInitial();
}

class LearningReportLoading extends LearningReportState {
  const LearningReportLoading();
}

/// Model data satu entri riwayat kuis
class QuizRecord {
  final String materialTitle;
  final String type; // 'quick_check' | 'quiz_utama'
  final int score;
  final int totalQuestions;
  final bool passed;
  final DateTime date;

  const QuizRecord({
    required this.materialTitle,
    required this.type,
    required this.score,
    required this.totalQuestions,
    required this.passed,
    required this.date,
  });

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;
}

/// Model data satu titik pada grafik tren
class TrendPoint {
  final DateTime date;
  final double scorePercent;
  final String label;

  const TrendPoint({
    required this.date,
    required this.scorePercent,
    required this.label,
  });
}

class LearningReportLoaded extends LearningReportState {
  final String childName;
  final int totalQuizzes;
  final int totalPassed;
  final double averageScore;
  final List<QuizRecord> quizHistory;
  final List<TrendPoint> trendData;

  const LearningReportLoaded({
    required this.childName,
    required this.totalQuizzes,
    required this.totalPassed,
    required this.averageScore,
    required this.quizHistory,
    required this.trendData,
  });

  @override
  List<Object?> get props => [
        childName,
        totalQuizzes,
        totalPassed,
        averageScore,
        quizHistory,
        trendData,
      ];
}

class LearningReportError extends LearningReportState {
  final String message;

  const LearningReportError(this.message);

  @override
  List<Object?> get props => [message];
}
