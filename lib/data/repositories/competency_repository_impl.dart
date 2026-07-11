import 'dart:async';
import '../../data/models/competency_model.dart';
import '../../domain/repositories/competency_repository.dart';

class CompetencyRepositoryImpl implements CompetencyRepository {
  @override
  Future<CompetencyModel> fetchClassCompetency(String classId) async {
    // Mensimulasikan jeda respons pemanggilan API / kalkulasi real-time
    await Future.delayed(const Duration(milliseconds: 1000));

    // Menghasilkan data dinamis berdasarkan kode kelas agar grafik bervariasi antar kelas
    final hash = classId.hashCode;
    
    final average = 72.5 + (hash % 12); // Rata-rata berkisar 72.5 - 84.5
    
    final topics = [
      MistakeTopicModel(
        topic: 'Struktur & Siklus Hidup Virus',
        errorRate: 42.0 + (hash % 18), // 42.0% - 60.0%
      ),
      MistakeTopicModel(
        topic: 'Pengelompokan Fungi & Peran Jamur',
        errorRate: 31.0 + (hash % 14), // 31.0% - 45.0%
      ),
      MistakeTopicModel(
        topic: 'Keanekaragaman Hayati Tingkat Gen & Jenis',
        errorRate: 20.0 + (hash % 10), // 20.0% - 30.0%
      ),
    ];

    final mastery = {
      'Pemahaman Konsep': 0.76 + ((hash % 6) / 40.0), // 0.76 - 0.91
      'Penerapan Teori': 0.68 + ((hash % 8) / 45.0),
      'Analisis Masalah': 0.54 + ((hash % 11) / 50.0),
      'Evaluasi Langkah': 0.70 + ((hash % 5) / 35.0),
      'Metakognisi Siswa': 0.61 + ((hash % 9) / 40.0),
    };

    return CompetencyModel(
      classId: classId,
      averageScore: average,
      highestMistakeTopics: topics,
      competencyMastery: mastery,
    );
  }
}
