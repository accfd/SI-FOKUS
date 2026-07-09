import '../../data/models/analytics_model.dart';

abstract class AnalyticsRepository {
  Future<ClassAnalyticsModel> fetchClassAnalytics(String classId);
}
