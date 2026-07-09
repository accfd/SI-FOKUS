import '../../data/models/talent_recommendation_model.dart';

abstract class TalentRepository {
  Future<List<TalentRecommendationModel>> fetchTalentRecommendations(String teacherId);
}
