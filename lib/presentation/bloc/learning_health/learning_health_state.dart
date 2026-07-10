import 'package:equatable/equatable.dart';

abstract class LearningHealthState extends Equatable {
  const LearningHealthState();

  @override
  List<Object?> get props => [];
}

class LearningHealthInitial extends LearningHealthState {
  const LearningHealthInitial();
}

class LearningHealthLoading extends LearningHealthState {
  const LearningHealthLoading();
}

enum HealthStatus { healthy, moderate, attention }

class HealthIndicator {
  final String label;
  final String value;
  final double progress; // 0.0 to 1.0
  final HealthStatus status;
  final String description;

  const HealthIndicator({
    required this.label,
    required this.value,
    required this.progress,
    required this.status,
    required this.description,
  });
}

class LearningHealthLoaded extends LearningHealthState {
  final String childName;
  final int studyDaysThisWeek; // Konsistensi belajar
  final double averageFocusScore; // Tingkat fokus
  final int totalStudyDurationMinutes; // Aktivitas belajar
  final int targetStudyDurationMinutes; // Target belajar
  final double completionRate; // Frekuensi penyelesaian materi tepat waktu

  final HealthStatus overallHealth;
  final List<HealthIndicator> indicators;

  const LearningHealthLoaded({
    required this.childName,
    required this.studyDaysThisWeek,
    required this.averageFocusScore,
    required this.totalStudyDurationMinutes,
    required this.targetStudyDurationMinutes,
    required this.completionRate,
    required this.overallHealth,
    required this.indicators,
  });

  @override
  List<Object?> get props => [
        childName,
        studyDaysThisWeek,
        averageFocusScore,
        totalStudyDurationMinutes,
        targetStudyDurationMinutes,
        completionRate,
        overallHealth,
        indicators,
      ];
}

class LearningHealthError extends LearningHealthState {
  final String message;

  const LearningHealthError(this.message);

  @override
  List<Object?> get props => [message];
}
