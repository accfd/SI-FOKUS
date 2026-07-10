import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/go_router.dart';
import 'domain/repositories/auth_repository.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/class_repository.dart';
import 'data/repositories/class_repository_impl.dart';
import 'domain/repositories/material_repository.dart';
import 'data/repositories/material_repository_impl.dart';
import 'domain/repositories/assessment_repository.dart';
import 'data/repositories/assessment_repository_impl.dart';
import 'domain/repositories/competency_repository.dart';
import 'data/repositories/competency_repository_impl.dart';
import 'domain/repositories/intervention_repository.dart';
import 'data/repositories/intervention_repository_impl.dart';
import 'domain/repositories/analytics_repository.dart';
import 'data/repositories/analytics_repository_impl.dart';
import 'domain/repositories/talent_repository.dart';
import 'data/repositories/talent_repository_impl.dart';
import 'domain/repositories/resource_repository.dart';
import 'data/repositories/resource_repository_impl.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/class/class_bloc.dart';
import 'presentation/bloc/material/material_bloc.dart';
import 'presentation/bloc/assessment/assessment_bloc.dart';
import 'presentation/bloc/competency/competency_bloc.dart';
import 'presentation/bloc/intervention/intervention_bloc.dart';
import 'presentation/bloc/analytics/analytics_bloc.dart';
import 'presentation/bloc/talent/talent_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDummyKeyForLocalWebTestingOnly",
          appId: "1:1234567890:web:dummyappid",
          messagingSenderId: "1234567890",
          projectId: "si-fokus-dummy",
          storageBucket: "si-fokus-dummy.appspot.com",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(),
        ),
        RepositoryProvider<ClassRepository>(
          create: (context) => ClassRepositoryImpl(),
        ),
        RepositoryProvider<MaterialRepository>(
          create: (context) => MaterialRepositoryImpl(),
        ),
        RepositoryProvider<AssessmentRepository>(
          create: (context) => AssessmentRepositoryImpl(),
        ),
        RepositoryProvider<CompetencyRepository>(
          create: (context) => CompetencyRepositoryImpl(),
        ),
        RepositoryProvider<InterventionRepository>(
          create: (context) => InterventionRepositoryImpl(),
        ),
        RepositoryProvider<AnalyticsRepository>(
          create: (context) => AnalyticsRepositoryImpl(),
        ),
        RepositoryProvider<TalentRepository>(
          create: (context) => TalentRepositoryImpl(),
        ),
        RepositoryProvider<ResourceRepository>(
          create: (context) => ResourceRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(const GetUserDataRequested()),
          ),
          BlocProvider<ClassBloc>(
            create: (context) => ClassBloc(
              classRepository: context.read<ClassRepository>(),
            ),
          ),
          BlocProvider<MaterialBloc>(
            create: (context) => MaterialBloc(
              materialRepository: context.read<MaterialRepository>(),
            ),
          ),
          BlocProvider<AssessmentBloc>(
            create: (context) => AssessmentBloc(
              assessmentRepository: context.read<AssessmentRepository>(),
            ),
          ),
          BlocProvider<CompetencyBloc>(
            create: (context) => CompetencyBloc(
              competencyRepository: context.read<CompetencyRepository>(),
            ),
          ),
          BlocProvider<InterventionBloc>(
            create: (context) => InterventionBloc(
              interventionRepository: context.read<InterventionRepository>(),
            ),
          ),
          BlocProvider<AnalyticsBloc>(
            create: (context) => AnalyticsBloc(
              analyticsRepository: context.read<AnalyticsRepository>(),
            ),
          ),
          BlocProvider<TalentBloc>(
            create: (context) => TalentBloc(
              talentRepository: context.read<TalentRepository>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'SI-FOKUS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
