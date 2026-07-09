import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../models/assessment_model.dart';
import '../models/question_model.dart';
import 'mock_db.dart';

bool get isMockMode {
  try {
    return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
  } catch (_) {
    return true;
  }
}

class AssessmentRepositoryImpl implements AssessmentRepository {
  final FirebaseFirestore? _firestore;
  final _uuid = const Uuid();

  AssessmentRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = isMockMode ? null : (firestore ?? FirebaseFirestore.instance);

  @override
  Future<AssessmentModel?> fetchAssessmentByMaterial(String materialId, String type) async {
    if (isMockMode) {
      final allAssessments = await MockDb.getAll('assessments');
      final match = allAssessments.firstWhere(
        (a) => a['materialId'] == materialId && a['type'] == type,
        orElse: () => const {},
      );
      if (match.isEmpty) return null;
      return AssessmentModel.fromJson(match);
    }

    final query = await _firestore!
        .collection('assessments')
        .where('materialId', isEqualTo: materialId)
        .where('type', isEqualTo: type)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return AssessmentModel.fromJson(query.docs.first.data());
  }

  @override
  Future<void> updateAssessmentQuestions(String assessmentId, List<QuestionModel> questions) async {
    if (isMockMode) {
      final data = await MockDb.get('assessments', assessmentId);
      if (data != null) {
        data['questions'] = questions.map((q) => q.toJson()).toList();
        await MockDb.save('assessments', assessmentId, data);
      }
      return;
    }

    await _firestore!.collection('assessments').doc(assessmentId).update({
      'questions': questions.map((q) => q.toJson()).toList(),
    });
  }

  @override
  Future<void> updateQuizConfiguration({
    required String assessmentId,
    required DateTime startDate,
    required DateTime endDate,
    required int durationMinutes,
    required bool isPublished,
  }) async {
    if (isMockMode) {
      final data = await MockDb.get('assessments', assessmentId);
      if (data != null) {
        data['startDate'] = startDate.toIso8601String();
        data['endDate'] = endDate.toIso8601String();
        data['durationMinutes'] = durationMinutes;
        data['isPublished'] = isPublished;
        await MockDb.save('assessments', assessmentId, data);
      }
      return;
    }

    await _firestore!.collection('assessments').doc(assessmentId).update({
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'isPublished': isPublished,
    });
  }

  @override
  Future<AssessmentModel> generateAssessment({
    required String materialId,
    required String classId,
    required String type,
    required String materialTitle,
    required String fileUrl,
  }) async {
    final existing = await fetchAssessmentByMaterial(materialId, type);
    if (existing != null) {
      return existing;
    }

    // Simulasi pemrosesan dokumen oleh AI Gemini
    await Future.delayed(const Duration(seconds: 3));

    final count = type == 'quick_check' ? 3 : 10;
    final questions = _generateMockQuestions(materialTitle, type, count);

    final assessment = AssessmentModel(
      assessmentId: _uuid.v4(),
      materialId: materialId,
      classId: classId,
      type: type,
      questions: questions,
    );

    if (isMockMode) {
      await MockDb.save('assessments', assessment.assessmentId, assessment.toJson());
      return assessment;
    }

    await _firestore!.collection('assessments').doc(assessment.assessmentId).set(assessment.toJson());
    return assessment;
  }

  // ==========================================
  // HELPER METHODS (MOCK QUESTION GENERATOR)
  // ==========================================

  List<QuestionModel> _generateMockQuestions(String title, String type, int count) {
    final lowerTitle = title.toLowerCase();
    
    List<Map<String, dynamic>> selectedBank = _generalBank;
    if (lowerTitle.contains('matematika') || lowerTitle.contains('aljabar') || lowerTitle.contains('hitung')) {
      selectedBank = _mathBank;
    } else if (lowerTitle.contains('sejarah') || lowerTitle.contains('indonesia') || lowerTitle.contains('perang')) {
      selectedBank = _historyBank;
    } else if (lowerTitle.contains('sains') || lowerTitle.contains('biologi') || lowerTitle.contains('sel') || lowerTitle.contains('fisika')) {
      selectedBank = _scienceBank;
    }

    final random = Random();
    final List<QuestionModel> questions = [];
    final bankSize = selectedBank.length;

    for (int i = 0; i < count; i++) {
      final bankIndex = (i + random.nextInt(3)) % bankSize;
      final rawItem = selectedBank[bankIndex];

      questions.add(
        QuestionModel(
          questionId: 'q_${type}_${i}_${_uuid.v4().substring(0, 4)}',
          questionText: '[AI Generated] ${rawItem['questionText']}',
          options: List<String>.from(rawItem['options']),
          correctAnswerIndex: rawItem['correctAnswerIndex'] as int,
        ),
      );
    }

    return questions;
  }

  // ==========================================
  // BANK SOAL TEMPLATE MOCK
  // ==========================================

  static const List<Map<String, dynamic>> _mathBank = [
    {
      'questionText': 'Jika 2x + 5 = 15, berapakah nilai x?',
      'options': ['x = 3', 'x = 5', 'x = 4', 'x = 10'],
      'correctAnswerIndex': 1,
    },
    {
      'questionText': 'Manakah dari berikut ini yang merupakan contoh persamaan kuadrat?',
      'options': ['y = 2x + 3', 'y = x^2 - 4', 'y = 3/x', 'y = log(x)'],
      'correctAnswerIndex': 1,
    },
    {
      'questionText': 'Berapakah luas segitiga dengan alas 10 cm dan tinggi 8 cm?',
      'options': ['80 cm^2', '40 cm^2', '20 cm^2', '18 cm^2'],
      'correctAnswerIndex': 1,
    },
    {
      'questionText': 'Variabel dalam persamaan aljabar didefinisikan sebagai...',
      'options': ['Angka tetap', 'Simbol yang mewakili nilai tidak diketahui', 'Kunci jawaban', 'Hasil akhir perkalian'],
      'correctAnswerIndex': 1,
    },
    {
      'questionText': 'Hasil dari perkalian matriks identitas dengan matriks A adalah...',
      'options': ['Matriks Nol', 'Matriks A itu sendiri', 'Kebalikan dari matriks A', 'Matriks Transpose A'],
      'correctAnswerIndex': 1,
    },
    {
      'questionText': 'Berapakah akar pangkat dua dari 144?',
      'options': ['11', '12', '13', '14'],
      'correctAnswerIndex': 1,
    },
  ];

  static const List<Map<String, dynamic>> _historyBank = [
    {
      'questionText': 'Kapan proklamasi kemerdekaan Republik Indonesia dibacakan?',
      'options': ['17 Agustus 1945', '1 Juni 1945', '18 Agustus 1945', '20 Mei 1908'],
      'correctAnswerIndex': 0,
    },
    {
      'questionText': 'Siapakah tokoh yang membacakan naskah Proklamasi Kemerdekaan Indonesia?',
      'options': ['Drs. Mohammad Hatta', 'Ir. Soekarno', 'Sutan Sjahrir', 'Sayuti Melik'],
      'correctAnswerIndex': 1,
    },
    {
      'questionText': 'Di kota manakah naskah proklamasi dirumuskan?',
      'options': ['Bandung', 'Yogyakarta', 'Jakarta', 'Surabaya'],
      'correctAnswerIndex': 2,
    },
    {
      'questionText': 'Peristiwa Rengasdengklok terjadi karena adanya perbedaan pendapat mengenai...',
      'options': ['Pembagian wilayah RI', 'Waktu pelaksanaan Proklamasi', 'Struktur kabinet pertama', 'Pemilihan Presiden'],
      'correctAnswerIndex': 1,
    },
    {
      'questionText': 'Siapakah pencipta lagu kebangsaan Indonesia Raya?',
      'options': ['W.R. Soepratman', 'Ibu Soed', 'L. Manik', 'Kusbini'],
      'correctAnswerIndex': 0,
    },
  ];

  static const List<Map<String, dynamic>> _scienceBank = [
    {
      'questionText': 'Organel sel yang berfungsi sebagai tempat respirasi sel dan penghasil energi adalah...',
      'options': ['Ribosom', 'Kloroplas', 'Mitokondria', 'Lisosom'],
      'correctAnswerIndex': 2,
    },
    {
      'questionText': 'Zat hijau daun pada tumbuhan yang berfungsi menyerap cahaya matahari disebut...',
      'options': ['Karoten', 'Klorofil', 'Sitoplasma', 'Lisosom'],
      'correctAnswerIndex': 1,
    },
    {
      'questionText': 'Hukum Gravitasi Universal pertama kali dirumuskan oleh...',
      'options': ['Albert Einstein', 'Isaac Newton', 'Galileo Galilei', 'Nikola Tesla'],
      'correctAnswerIndex': 1,
    },
    {
      'questionText': 'Gas apakah yang paling banyak menyusun atmosfer bumi kita?',
      'options': ['Oksigen', 'Karbondioksida', 'Nitrogen', 'Hidrogen'],
      'correctAnswerIndex': 2,
    },
    {
      'questionText': 'Manakah dari berikut ini yang merupakan contoh perubahan kimia?',
      'options': ['Es mencair', 'Besi berkarat', 'Air menguap', 'Kertas dipotong'],
      'correctAnswerIndex': 1,
    },
  ];

  static const List<Map<String, dynamic>> _generalBank = [
    {
      'questionText': 'Apakah ide pokok utama dari paragraf pertama dokumen yang baru diunggah?',
      'options': ['Pengenalan konsep dasar', 'Sejarah penemuan materi', 'Daftar pustaka', 'Kesimpulan akhir'],
      'correctAnswerIndex': 0,
    },
    {
      'questionText': 'Mengapa pemahaman tentang materi ini sangat krusial bagi siswa?',
      'options': ['Untuk syarat kelulusan', 'Karena merupakan fondasi dasar materi selanjutnya', 'Membantu menghafal rumus', 'Mempersingkat waktu belajar'],
      'correctAnswerIndex': 1,
    },
    {
      'questionText': 'Berdasarkan dokumen, kesimpulan apa yang dapat ditarik terkait sub-topik?',
      'options': ['Penerapan konsep masih sulit dilakukan', 'Konsep ini sangat relevan untuk kehidupan sehari-hari', 'Tidak ada korelasi antar sub-topik', 'Materi ini sudah usang'],
      'correctAnswerIndex': 1,
    },
  ];
}
