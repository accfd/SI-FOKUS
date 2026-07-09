abstract class InterventionEvent {
  const InterventionEvent();
}

class FetchInterventionDataEvent extends InterventionEvent {
  final String classId;
  final String materialId;

  const FetchInterventionDataEvent({
    required this.classId,
    required this.materialId,
  });
}

class SendNotificationRequested extends InterventionEvent {
  final String studentId;
  final String studentName;
  final String message;

  const SendNotificationRequested({
    required this.studentId,
    required this.studentName,
    required this.message,
  });
}
