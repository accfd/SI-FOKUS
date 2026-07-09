import 'package:equatable/equatable.dart';

abstract class QuickCheckEvent extends Equatable {
  const QuickCheckEvent();

  @override
  List<Object?> get props => [];
}

class LoadQuickCheck extends QuickCheckEvent {
  final String materialId;
  final String studentId;
  final String assessmentType;

  const LoadQuickCheck({
    required this.materialId, 
    required this.studentId,
    this.assessmentType = 'quick_check',
  });

  @override
  List<Object?> get props => [materialId, studentId, assessmentType];
}

class SubmitQuickCheck extends QuickCheckEvent {
  final Map<String, int> answers; // questionId -> selectedOptionIndex
  
  const SubmitQuickCheck({required this.answers});

  @override
  List<Object?> get props => [answers];
}
