import 'package:equatable/equatable.dart';

abstract class TalentReportEvent extends Equatable {
  const TalentReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadTalentReport extends TalentReportEvent {
  final String studentUid;

  const LoadTalentReport({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}
