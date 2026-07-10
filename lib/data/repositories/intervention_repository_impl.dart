import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/intervention_model.dart';
import '../../domain/repositories/intervention_repository.dart';
import 'mock_db.dart';

bool get isMockMode {
  try {
    return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
  } catch (_) {
    return true;
  }
}

class InterventionRepositoryImpl implements InterventionRepository {
  final FirebaseFirestore? _firestore;
  final _uuid = const Uuid();

  InterventionRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = isMockMode ? null : (firestore ?? FirebaseFirestore.instance);

  @override
  Future<InterventionModel> fetchInterventionData(String classId, String materialId) async {
    if (isMockMode) {
      final allInterventions = await MockDb.getAll('interventions');
      final match = allInterventions.firstWhere(
        (i) => i['classId'] == classId && i['materialId'] == materialId,
        orElse: () => const {},
      );

      if (match.isNotEmpty) {
        return InterventionModel.fromJson(match);
      }

      final intervention = InterventionModel(
        interventionId: _uuid.v4(),
        classId: classId,
        materialId: materialId,
        summaryAlert: 'Belum ada data aktivitas siswa untuk materi ini.',
        recommendations: const [],
        individualInterventions: const [],
      );

      await MockDb.save('interventions', intervention.interventionId, intervention.toJson());
      return intervention;
    }

    final query = await _firestore!
        .collection('interventions')
        .where('classId', isEqualTo: classId)
        .where('materialId', isEqualTo: materialId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return InterventionModel.fromJson(query.docs.first.data());
    }

    final intervention = InterventionModel(
      interventionId: _uuid.v4(),
      classId: classId,
      materialId: materialId,
      summaryAlert: 'Belum ada data aktivitas siswa untuk materi ini.',
      recommendations: const [],
      individualInterventions: const [],
    );

    await _firestore.collection('interventions').doc(intervention.interventionId).set(intervention.toJson());
    return intervention;
  }

  @override
  Future<void> sendQuickNotification({required String studentId, required String message}) async {
    await Future.delayed(const Duration(milliseconds: 800));
  }
}
