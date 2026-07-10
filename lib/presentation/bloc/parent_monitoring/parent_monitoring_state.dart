import 'package:equatable/equatable.dart';

abstract class ParentMonitoringState extends Equatable {
  const ParentMonitoringState();

  @override
  List<Object?> get props => [];
}

class ParentMonitoringInitial extends ParentMonitoringState {
  const ParentMonitoringInitial();
}

class ParentMonitoringLoading extends ParentMonitoringState {
  const ParentMonitoringLoading();
}

class ParentMonitoringLoaded extends ParentMonitoringState {
  final String childName;
  final String childEmail;
  final String className;
  final int childXp;
  final int childLevel;
  final List<String> childBadges;
  final double averageFocusScore;
  final int totalActivities;
  final int quizzesPassed;
  final int quizzesFailed;
  final List<Map<String, dynamic>> recentActivities;
  final List<Map<String, dynamic>> quizResults;

  const ParentMonitoringLoaded({
    required this.childName,
    required this.childEmail,
    required this.className,
    required this.childXp,
    required this.childLevel,
    required this.childBadges,
    required this.averageFocusScore,
    required this.totalActivities,
    required this.quizzesPassed,
    required this.quizzesFailed,
    required this.recentActivities,
    required this.quizResults,
  });

  @override
  List<Object?> get props => [
        childName,
        childEmail,
        className,
        childXp,
        childLevel,
        childBadges,
        averageFocusScore,
        totalActivities,
        quizzesPassed,
        quizzesFailed,
        recentActivities,
        quizResults,
      ];
}

class ParentMonitoringNoChild extends ParentMonitoringState {
  const ParentMonitoringNoChild();
}

class ParentMonitoringError extends ParentMonitoringState {
  final String message;

  const ParentMonitoringError(this.message);

  @override
  List<Object?> get props => [message];
}
