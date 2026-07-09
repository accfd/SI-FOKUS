import 'package:equatable/equatable.dart';

abstract class GamificationEvent extends Equatable {
  const GamificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadLeaderboard extends GamificationEvent {
  // Secara ideal, ditarik berdasarkan classId. 
  // Jika global/sementara, tidak perlu argumen.
  const LoadLeaderboard();
}

class ProcessQuizResult extends GamificationEvent {
  final String studentId;
  final double focusScore;
  final double quizScore;

  const ProcessQuizResult({
    required this.studentId,
    required this.focusScore,
    required this.quizScore,
  });

  @override
  List<Object?> get props => [studentId, focusScore, quizScore];
}
