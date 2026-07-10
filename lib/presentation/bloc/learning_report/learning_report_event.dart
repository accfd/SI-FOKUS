import 'package:equatable/equatable.dart';

abstract class LearningReportEvent extends Equatable {
  const LearningReportEvent();

  @override
  List<Object?> get props => [];
}

/// Memuat laporan belajar anak berdasarkan UID anak yang dipantau.
class LoadLearningReport extends LearningReportEvent {
  final String studentUid;

  const LoadLearningReport({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}
