import 'package:equatable/equatable.dart';

abstract class ParentMonitoringEvent extends Equatable {
  const ParentMonitoringEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when the parent dashboard opens.
/// [parentUid] is used to look up the parent's linkedStudentUid first,
/// then stream the child's data.
class LoadChildData extends ParentMonitoringEvent {
  final String parentUid;

  const LoadChildData({required this.parentUid});

  @override
  List<Object?> get props => [parentUid];
}

/// Fired internally when the child data stream emits a new snapshot.
class ChildDataUpdated extends ParentMonitoringEvent {
  final Map<String, dynamic> childData;
  final List<Map<String, dynamic>> recentActivities;
  final List<Map<String, dynamic>> quizResults;

  const ChildDataUpdated({
    required this.childData,
    required this.recentActivities,
    required this.quizResults,
  });

  @override
  List<Object?> get props => [childData, recentActivities, quizResults];
}
