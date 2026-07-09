import '../../data/models/assessment_model.dart';
import '../../data/models/question_model.dart';

abstract class AssessmentRepository {
  Future<AssessmentModel?> fetchAssessmentByMaterial(String materialId, String type);

  Future<AssessmentModel> generateAssessment({
    required String materialId,
    required String classId,
    required String type,
    required String materialTitle,
    required String fileUrl,
  });

  Future<void> updateAssessmentQuestions(String assessmentId, List<QuestionModel> questions);

  Future<void> updateQuizConfiguration({
    required String assessmentId,
    required DateTime startDate,
    required DateTime endDate,
    required int durationMinutes,
    required bool isPublished,
  });
}
