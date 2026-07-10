import 'package:equatable/equatable.dart';

abstract class LearningHealthEvent extends Equatable {
  const LearningHealthEvent();

  @override
  List<Object?> get props => [];
}

/// Memuat data kesehatan belajar anak.
class LoadLearningHealth extends LearningHealthEvent {
  final String studentUid;

  const LoadLearningHealth({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}
