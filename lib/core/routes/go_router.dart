import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/guru/guru_dashboard_page.dart';
import '../../presentation/pages/guru/class_detail_guru_page.dart';
import '../../presentation/pages/guru/upload_material_page.dart';
import '../../presentation/pages/guru/edit_assessment_page.dart';
import '../../presentation/pages/guru/quiz_config_page.dart';
import '../../presentation/pages/guru/competency_dashboard_page.dart';
import '../../presentation/pages/guru/learning_intervention_page.dart';
import '../../presentation/pages/guru/learning_analytics_page.dart';
import '../../presentation/pages/guru/talent_recommendation_page.dart';
import '../../presentation/pages/guru/manage_learning_resource_page.dart';
import '../../presentation/pages/dashboard/siswa_dashboard_page.dart';
import '../../presentation/pages/dashboard/orangtua_dashboard_page.dart';
import '../../presentation/pages/orangtua/learning_report_page.dart';
import '../../presentation/pages/orangtua/learning_health_page.dart';
import '../../presentation/pages/orangtua/parent_recommendation_page.dart';
import '../../presentation/pages/orangtua/talent_report_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/dashboard/guru',
        name: 'guru_dashboard',
        builder: (context, state) => const GuruDashboardPage(),
        routes: [
          GoRoute(
            path: 'talent',
            name: 'talent_recommendation',
            builder: (context, state) => const TalentRecommendationPage(),
          ),
          GoRoute(
            path: 'class/:classId',
            name: 'class_detail_guru',
            builder: (context, state) {
              final classId = state.pathParameters['classId'] ?? '';
              return ClassDetailGuruPage(classId: classId);
            },
            routes: [
              GoRoute(
                path: 'upload',
                name: 'upload_material',
                builder: (context, state) {
                  final classId = state.pathParameters['classId'] ?? '';
                  final materialId = state.uri.queryParameters['materialId'];
                  return UploadMaterialPage(
                    classId: classId,
                    initialMaterialId: materialId,
                  );
                },
              ),
              GoRoute(
                path: 'material/:materialId/assessment/:type',
                name: 'edit_assessment',
                builder: (context, state) {
                  final classId = state.pathParameters['classId'] ?? '';
                  final materialId = state.pathParameters['materialId'] ?? '';
                  final type = state.pathParameters['type'] ?? '';
                  return EditAssessmentPage(
                    classId: classId,
                    materialId: materialId,
                    type: type,
                  );
                },
              ),
              GoRoute(
                path: 'material/:materialId/assessment/:type/config',
                name: 'quiz_config',
                builder: (context, state) {
                  final classId = state.pathParameters['classId'] ?? '';
                  final materialId = state.pathParameters['materialId'] ?? '';
                  final type = state.pathParameters['type'] ?? '';
                  return QuizConfigPage(
                    classId: classId,
                    materialId: materialId,
                    type: type,
                  );
                },
              ),
              GoRoute(
                path: 'competency',
                name: 'competency_dashboard',
                builder: (context, state) {
                  final classId = state.pathParameters['classId'] ?? '';
                  return CompetencyDashboardPage(classId: classId);
                },
              ),
              GoRoute(
                path: 'material/:materialId/intervention',
                name: 'learning_intervention',
                builder: (context, state) {
                  final classId = state.pathParameters['classId'] ?? '';
                  final materialId = state.pathParameters['materialId'] ?? '';
                  return LearningInterventionPage(
                    classId: classId,
                    materialId: materialId,
                  );
                },
              ),
              GoRoute(
                path: 'analytics',
                name: 'learning_analytics',
                builder: (context, state) {
                  final classId = state.pathParameters['classId'] ?? '';
                  return LearningAnalyticsPage(classId: classId);
                },
              ),
              GoRoute(
                path: 'material/:materialId/resources',
                name: 'manage_learning_resources',
                builder: (context, state) {
                  final classId = state.pathParameters['classId'] ?? '';
                  final materialId = state.pathParameters['materialId'] ?? '';
                  return ManageLearningResourcePage(
                    classId: classId,
                    materialId: materialId,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/dashboard/siswa',
        name: 'siswa_dashboard',
        builder: (context, state) => const SiswaDashboardPage(),
      ),
      GoRoute(
        path: '/dashboard/orangtua',
        name: 'orangtua_dashboard',
        builder: (context, state) => const OrangTuaDashboardPage(),
        routes: [
          GoRoute(
            path: 'learning-report',
            name: 'learning_report',
            builder: (context, state) => const LearningReportPage(),
          ),
          GoRoute(
            path: 'learning-health',
            name: 'learning_health',
            builder: (context, state) => const LearningHealthPage(),
          ),
          GoRoute(
            path: 'parent-recommendation',
            name: 'parent_recommendation',
            builder: (context, state) => const ParentRecommendationPage(),
          ),
          GoRoute(
            path: 'talent-report',
            name: 'talent_report',
            builder: (context, state) => const TalentReportPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Halaman tidak ditemukan: ${state.uri}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}
