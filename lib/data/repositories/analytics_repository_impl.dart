import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../data/models/analytics_model.dart';
import '../../domain/repositories/analytics_repository.dart';
import 'mock_db.dart';

bool get isMockMode {
  try {
    return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
  } catch (_) {
    return true;
  }
}

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final FirebaseFirestore? _firestore;

  AnalyticsRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = isMockMode ? null : (firestore ?? FirebaseFirestore.instance);

  @override
  Future<ClassAnalyticsModel> fetchClassAnalytics(String classId) async {
    if (isMockMode) {
      final match = await MockDb.get('analytics', classId);
      if (match != null) {
        return ClassAnalyticsModel.fromJson(match);
      }

      final analytics = ClassAnalyticsModel(
        classId: classId,
        quizTrends: [
          QuizTrendPoint(quizName: 'Kuis 1', averageScore: 68.2),
          QuizTrendPoint(quizName: 'Kuis 2', averageScore: 74.5),
          QuizTrendPoint(quizName: 'Kuis 3', averageScore: 71.0),
          QuizTrendPoint(quizName: 'Kuis 4', averageScore: 80.2),
          QuizTrendPoint(quizName: 'Kuis 5', averageScore: 86.4),
        ],
        readingStats: [
          ModuleReadingStat(
            moduleTitle: 'Persamaan Linear Satu Variabel',
            avgReadingMinutes: 28.5,
            avgQuizScore: 72.0,
          ),
          ModuleReadingStat(
            moduleTitle: 'Operasi Transpose Matriks',
            avgReadingMinutes: 44.0,
            avgQuizScore: 84.5,
          ),
          ModuleReadingStat(
            moduleTitle: 'Teorema Pythagoras Aljabar',
            avgReadingMinutes: 18.0,
            avgQuizScore: 65.5,
          ),
        ],
        studentSummaries: [
          StudentAnalyticsSummary(
            studentId: 'std_1',
            studentName: 'Aditya Pratama',
            avgQuizScore: 88.5,
            completedModulesCount: 3,
          ),
          StudentAnalyticsSummary(
            studentId: 'std_2',
            studentName: 'Budi Santoso',
            avgQuizScore: 71.2,
            completedModulesCount: 2,
          ),
          StudentAnalyticsSummary(
            studentId: 'std_3',
            studentName: 'Citra Lestari',
            avgQuizScore: 92.0,
            completedModulesCount: 3,
          ),
          StudentAnalyticsSummary(
            studentId: 'std_4',
            studentName: 'Dewi Handayani',
            avgQuizScore: 78.4,
            completedModulesCount: 3,
          ),
        ],
      );

      await MockDb.save('analytics', classId, analytics.toJson());
      return analytics;
    }

    final doc = await _firestore!.collection('analytics').doc(classId).get();

    if (doc.exists && doc.data() != null) {
      return ClassAnalyticsModel.fromJson(doc.data()!);
    }

    final analytics = ClassAnalyticsModel(
      classId: classId,
      quizTrends: [
        QuizTrendPoint(quizName: 'Kuis 1', averageScore: 68.2),
        QuizTrendPoint(quizName: 'Kuis 2', averageScore: 74.5),
        QuizTrendPoint(quizName: 'Kuis 3', averageScore: 71.0),
        QuizTrendPoint(quizName: 'Kuis 4', averageScore: 80.2),
        QuizTrendPoint(quizName: 'Kuis 5', averageScore: 86.4),
      ],
      readingStats: [
        ModuleReadingStat(
          moduleTitle: 'Persamaan Linear Satu Variabel',
          avgReadingMinutes: 28.5,
          avgQuizScore: 72.0,
        ),
        ModuleReadingStat(
          moduleTitle: 'Operasi Transpose Matriks',
          avgReadingMinutes: 44.0,
          avgQuizScore: 84.5,
        ),
        ModuleReadingStat(
          moduleTitle: 'Teorema Pythagoras Aljabar',
          avgReadingMinutes: 18.0,
          avgQuizScore: 65.5,
        ),
      ],
      studentSummaries: [
        StudentAnalyticsSummary(
          studentId: 'std_1',
          studentName: 'Aditya Pratama',
          avgQuizScore: 88.5,
          completedModulesCount: 3,
        ),
        StudentAnalyticsSummary(
          studentId: 'std_2',
          studentName: 'Budi Santoso',
          avgQuizScore: 71.2,
          completedModulesCount: 2,
        ),
        StudentAnalyticsSummary(
          studentId: 'std_3',
          studentName: 'Citra Lestari',
          avgQuizScore: 92.0,
          completedModulesCount: 3,
        ),
        StudentAnalyticsSummary(
          studentId: 'std_4',
          studentName: 'Dewi Handayani',
          avgQuizScore: 78.4,
          completedModulesCount: 3,
        ),
      ],
    );

    await _firestore.collection('analytics').doc(classId).set(analytics.toJson());
    return analytics;
  }
}
