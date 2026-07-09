import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/talent_recommendation_model.dart';
import '../../domain/repositories/talent_repository.dart';
import 'mock_db.dart';

bool get isMockMode {
  try {
    return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
  } catch (_) {
    return true;
  }
}

class TalentRepositoryImpl implements TalentRepository {
  final FirebaseFirestore? _firestore;
  final _uuid = const Uuid();

  TalentRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = isMockMode ? null : (firestore ?? FirebaseFirestore.instance);

  @override
  Future<List<TalentRecommendationModel>> fetchTalentRecommendations(String teacherId) async {
    if (isMockMode) {
      final allRecs = await MockDb.getAll('talent_recommendations');
      final teacherRecs = allRecs
          .where((r) => r['teacherId'] == teacherId)
          .map((r) => TalentRecommendationModel.fromJson(r))
          .toList();

      if (teacherRecs.isNotEmpty) {
        return teacherRecs;
      }

      // Generate default talent recommendations locally
      final generated = _generateDefaultRecommendations(teacherId);
      for (final rec in generated) {
        await MockDb.save('talent_recommendations', rec.recommendationId, rec.toJson());
      }
      return generated;
    }

    final query = await _firestore!
        .collection('talent_recommendations')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.map((doc) => TalentRecommendationModel.fromJson(doc.data())).toList();
    }

    // Jika belum ada di Firestore, generate & simpan ke Firestore
    final generated = _generateDefaultRecommendations(teacherId);
    for (final rec in generated) {
      await _firestore.collection('talent_recommendations').doc(rec.recommendationId).set(rec.toJson());
    }
    return generated;
  }

  List<TalentRecommendationModel> _generateDefaultRecommendations(String teacherId) {
    return [
      TalentRecommendationModel(
        recommendationId: _uuid.v4(),
        teacherId: teacherId,
        studentId: 'std_rem_1',
        studentName: 'Aditya Pratama',
        recommendedField: 'informatika',
        confidenceScore: 0.94,
        reasoning: 'Menunjukkan pemikiran komputasi dan logika aljabar linier yang luar biasa cepat. Kecepatan pengerjaan kuis di atas rata-rata dengan tingkat fokus 98%. Cocok untuk Olimpiade Sains Nasional bidang Informatika.',
      ),
      TalentRecommendationModel(
        recommendationId: _uuid.v4(),
        teacherId: teacherId,
        studentId: 'std_rem_3',
        studentName: 'Citra Lestari',
        recommendedField: 'sains',
        confidenceScore: 0.88,
        reasoning: 'Konsisten meraih nilai sempurna pada kuis kognitif dan memiliki ketahanan membaca materi sains yang tinggi tanpa menunjukkan gejala kejenuhan (idle rate sangat rendah). Sangat potensial untuk Olimpiade Astronomi atau Fisika.',
      ),
      TalentRecommendationModel(
        recommendationId: _uuid.v4(),
        teacherId: teacherId,
        studentId: 'std_rem_2',
        studentName: 'Budi Santoso',
        recommendedField: 'akademik',
        confidenceScore: 0.78,
        reasoning: 'Menunjukkan pola ketekunan yang stabil dan kurva perkembangan nilai kuis yang naik konsisten dari kuis 1 ke kuis 5. Direkomendasikan untuk program pembinaan akademik intensif kelas.',
      ),
    ];
  }
}
