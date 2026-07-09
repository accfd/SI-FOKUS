import '../../data/models/competency_model.dart';

abstract class CompetencyRepository {
  Future<CompetencyModel> fetchClassCompetency(String classId);
}
