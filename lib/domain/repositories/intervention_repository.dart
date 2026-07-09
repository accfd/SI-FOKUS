import '../../data/models/intervention_model.dart';

abstract class InterventionRepository {
  Future<InterventionModel> fetchInterventionData(String classId, String materialId);

  Future<void> sendQuickNotification({
    required String studentId,
    required String message,
  });
}
