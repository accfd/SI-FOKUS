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
        summaryAlert: '72% siswa belum memahami konsep dan perhitungan dasar sub-materi ini.',
        recommendations: [
          'Ulangi penjelasan sub-materi utama selama 20 menit pada pertemuan kelas berikutnya.',
          'Gunakan representasi grafis/media visual untuk menyederhanakan alur rumus yang rumit.',
          'Berikan kuis latihan mandiri terstruktur sebanyak 5 soal tambahan untuk mengunci pemahaman.',
        ],
        individualInterventions: [
          IndividualInterventionModel(
            studentId: 'std_rem_1',
            studentName: 'Aditya Pratama',
            message: 'Harap membaca kembali bagian sub-topik aljabar dan ulangi kuis evaluasi.',
          ),
          IndividualInterventionModel(
            studentId: 'std_rem_2',
            studentName: 'Budi Santoso',
            message: 'Fokuskan latihan Anda pada pengerjaan perkalian matriks transpose.',
          ),
          IndividualInterventionModel(
            studentId: 'std_rem_3',
            studentName: 'Citra Lestari',
            message: 'Ulas kembali lembar jawaban kuis utama bersama guru pendamping.',
          ),
        ],
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
      summaryAlert: '72% siswa belum memahami konsep dan perhitungan dasar sub-materi ini.',
      recommendations: [
        'Ulangi penjelasan sub-materi utama selama 20 menit pada pertemuan kelas berikutnya.',
        'Gunakan representasi grafis/media visual untuk menyederhanakan alur rumus yang rumit.',
        'Berikan kuis latihan mandiri terstruktur sebanyak 5 soal tambahan untuk mengunci pemahaman.',
      ],
      individualInterventions: [
        IndividualInterventionModel(
          studentId: 'std_rem_1',
          studentName: 'Aditya Pratama',
          message: 'Harap membaca kembali bagian sub-topik aljabar dan ulangi kuis evaluasi.',
        ),
        IndividualInterventionModel(
          studentId: 'std_rem_2',
          studentName: 'Budi Santoso',
          message: 'Fokuskan latihan Anda pada pengerjaan perkalian matriks transpose.',
        ),
        IndividualInterventionModel(
          studentId: 'std_rem_3',
          studentName: 'Citra Lestari',
          message: 'Ulas kembali lembar jawaban kuis utama bersama guru pendamping.',
        ),
      ],
    );

    await _firestore.collection('interventions').doc(intervention.interventionId).set(intervention.toJson());
    return intervention;
  }

  @override
  Future<void> sendQuickNotification({required String studentId, required String message}) async {
    await Future.delayed(const Duration(milliseconds: 800));
  }
}
