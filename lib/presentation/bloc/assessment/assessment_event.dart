import '../../../data/models/question_model.dart';

abstract class AssessmentEvent {
  const AssessmentEvent();
}

class FetchAssessmentByMaterial extends AssessmentEvent {
  final String materialId;
  final String type; // 'quick_check' | 'quiz_utama'

  const FetchAssessmentByMaterial({
    required this.materialId,
    required this.type,
  });
}

class GenerateAssessmentRequested extends AssessmentEvent {
  final String materialId;
  final String classId;
  final String type; // 'quick_check' | 'quiz_utama'
  final String materialTitle;
  final String fileUrl;

  const GenerateAssessmentRequested({
    required this.materialId,
    required this.classId,
    required this.type,
    required this.materialTitle,
    required this.fileUrl,
  });
}

class UpdateAssessmentQuestions extends AssessmentEvent {
  final String assessmentId;
  final List<QuestionModel> questions;
  final String materialId;
  final String type; // To reload after saving

  const UpdateAssessmentQuestions({
    required this.assessmentId,
    required this.questions,
    required this.materialId,
    required this.type,
  });
}

class UpdateQuizConfiguration extends AssessmentEvent {
  final String assessmentId;
  final DateTime startDate;
  final DateTime endDate;
  final int durationMinutes;
  final bool isPublished;
  final String materialId;
  final String type;

  const UpdateQuizConfiguration({
    required this.assessmentId,
    required this.startDate,
    required this.endDate,
    required this.durationMinutes,
    required this.isPublished,
    required this.materialId,
    required this.type,
  });
}
