import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../data/models/user_model.dart';
import '../../data/models/class_model.dart';
import '../../data/models/material_model.dart';
import '../../data/models/learning_resource_model.dart';
import '../../data/models/assessment_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/intervention_model.dart';
import '../../data/models/talent_recommendation_model.dart';
import '../../data/models/competency_model.dart';
import '../../data/repositories/mock_db.dart';

bool get _isMockMode {
  if (!kIsWeb) return false;
  try {
    return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
  } catch (_) {
    return true;
  }
}

class GuruSeeder {
  GuruSeeder._();

  static const String teacherUid = 'guru_budi_123';
  static const String teacherEmail = 'guru@test.com';

  static final List<String> studentNames = [
    'Adi Pratama', 'Bima Saputra', 'Citra Dewi', 'Dedi Kurniawan', 'Eka Putri',
    'Fajar Hidayat', 'Gita Lestari', 'Hadi Nugroho', 'Indah Sari', 'Joko Susanto',
    'Kartika Wulandari', 'Lukman Hakim', 'Maya Anggraini', 'Nanda Permata', 'Omar Fauzi'
  ];

  static Future<void> seedAll() async {
    debugPrint('=== MEMULAI SEEDING DATA DUMMY GURU ===');
    
    // 1. AKUN GURU
    final teacher = UserModel(
      uid: teacherUid,
      name: 'Budi Santoso',
      email: teacherEmail,
      role: 'guru',
      createdAt: DateTime.now(),
    );
    await _saveData('users', teacherUid, teacher.toJson(), teacher.toFirestore());

    // Simpan UID guru saat ini agar login otomatis bisa mengenali jika menggunakan mock
    if (_isMockMode) {
      await MockDb.setString('current_user_uid', teacherUid);
    }

    // 2. AKUN SISWA (15 Siswa)
    final List<UserModel> students = [];
    for (int i = 0; i < studentNames.length; i++) {
      final name = studentNames[i];
      final emailName = name.replaceAll(' ', '').toLowerCase();
      final student = UserModel(
        uid: 'siswa_${i + 1}',
        name: name,
        email: '$emailName@test.com',
        role: 'siswa',
        parentAccessCode: 'ACC${100 + i}',
        xp: 200 + (i * 150),
        level: (i % 5) + 1,
        unlockedBadges: i % 2 == 0 ? ['Bintang_Kelas', 'Rajin_Membaca'] : ['Rajin_Membaca'],
        createdAt: DateTime.now(),
      );
      students.add(student);
      await _saveData('users', student.uid, student.toJson(), student.toFirestore());
    }

    // 3. KELAS (2 Kelas)
    final class1 = ClassModel(
      classId: 'class_math_7a',
      className: 'Matematika VII-A',
      classCode: 'MATH7A23',
      subjectName: 'Matematika',
      teacherId: teacherUid,
      studentUids: List.generate(10, (idx) => 'siswa_${idx + 1}'),
    );
    await _saveData('classes', class1.classId, class1.toJson(), class1.toJson());

    final class2 = ClassModel(
      classId: 'class_ipa_7b',
      className: 'IPA VII-B',
      classCode: 'IPA7B456',
      subjectName: 'Ilmu Pengetahuan Alam',
      teacherId: teacherUid,
      studentUids: List.generate(10, (idx) => 'siswa_${idx + 6}'), // Overlap 5 siswa (siswa_6 - siswa_10)
    );
    await _saveData('classes', class2.classId, class2.toJson(), class2.toJson());

    // 4. MATERI PEMBELAJARAN (4 Materi)
    final mat1 = MaterialModel(
      materialId: 'mat_aljabar',
      classId: class1.classId,
      title: 'Aljabar Dasar',
      fileUrl: 'https://firebasestorage.example.com/materials/aljabar.pdf',
      fileType: 'pdf',
      summary: 'Aljabar adalah bagian dari matematika yang menggunakan simbol dan huruf untuk merepresentasikan angka dalam formula dan persamaan. Pada bab Aljabar Dasar ini, siswa mempelajari unsur-unsur aljabar seperti koefisien, variabel, konstanta, dan suku. Topik penting lainnya mencakup operasi penjumlahan, pengurangan, perkalian, serta pembagian pada bentuk aljabar sederhana. Kompetensi ini sangat krusial sebagai fondasi sebelum mempelajari persamaan linear, fungsi, dan kalkulus pada tingkat pendidikan yang lebih tinggi.',
      isPublished: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      aiProcessingStatus: 'done',
      topics: ['Pengertian Aljabar', 'Operasi Penjumlahan Aljabar', 'Soal Cerita Aljabar'],
      learningResources: [
        LearningResourceModel(
          resourceId: 'res_yt_aljabar',
          title: 'Video Edukasi Pengenalan Aljabar Dasar',
          type: 'youtube',
          url: 'https://www.youtube.com/watch?v=gT8vWn8R298',
        )
      ],
    );
    await _saveData('materials', mat1.materialId, mat1.toJson(), mat1.toFirestore());

    final mat2 = MaterialModel(
      materialId: 'mat_persamaan_linear',
      classId: class1.classId,
      title: 'Persamaan Linear Satu Variabel',
      fileUrl: 'https://firebasestorage.example.com/materials/persamaan_linear.pdf',
      fileType: 'pdf',
      summary: 'Persamaan Linear Satu Variabel (PLSV) merupakan kalimat terbuka yang dihubungkan oleh tanda sama dengan (=) dan hanya mempunyai satu variabel berpangkat satu. Pada materi ini, siswa diajarkan untuk menemukan nilai variabel yang membuat persamaan bernilai benar (penyelesaian persamaan). Langkah-langkah penyelesaian melibatkan operasi penjumlahan, pengurangan, perkalian, atau pembagian pada kedua ruas secara seimbang. Materi ini membekali siswa kemampuan memodelkan masalah sehari-hari ke dalam kalimat matematika aljabar.',
      isPublished: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      aiProcessingStatus: 'done',
      topics: ['Definisi PLSV', 'Penyelesaian Ruas Seimbang PLSV', 'Penerapan PLSV dalam Kehidupan'],
      learningResources: [
        LearningResourceModel(
          resourceId: 'res_yt_plsv',
          title: 'Cara Cepat Menyelesaikan Persamaan Linear',
          type: 'youtube',
          url: 'https://www.youtube.com/watch?v=e_wK7l-W-98',
        ),
        LearningResourceModel(
          resourceId: 'res_art_plsv',
          title: 'Artikel Pembahasan Lengkap PLSV di Blog',
          type: 'link',
          url: 'https://www.kelaspintar.id/blog/tips-pintar/persamaan-linear-satu-variabel-11234/',
        )
      ],
    );
    await _saveData('materials', mat2.materialId, mat2.toJson(), mat2.toFirestore());

    final mat3 = MaterialModel(
      materialId: 'mat_tata_surya',
      classId: class2.classId,
      title: 'Sistem Tata Surya',
      fileUrl: 'https://firebasestorage.example.com/materials/tata_surya.pdf',
      fileType: 'pdf',
      summary: 'Sistem Tata Surya adalah kumpulan benda langit yang terdiri atas sebuah bintang yang disebut Matahari dan semua objek yang terikat oleh gaya gravitasinya. Objek-objek tersebut termasuk delapan planet yang sudah diketahui dengan orbit berbentuk elips, lima planet kerdil/katai, 173 satelit alami yang telah diidentifikasi, dan miliaran benda langit lainnya seperti asteroid, meteoroid, dan komet. Siswa mempelajari karakteristik masing-masing planet mulai dari Merkurius hingga Neptunus serta teori pembentukan tata surya.',
      isPublished: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      aiProcessingStatus: 'done',
      topics: ['Karakteristik Matahari & Planet', 'Gaya Gravitasi Planet', 'Komet dan Asteroid'],
      learningResources: [],
    );
    await _saveData('materials', mat3.materialId, mat3.toJson(), mat3.toFirestore());

    final mat4 = MaterialModel(
      materialId: 'mat_ekosistem',
      classId: class2.classId,
      title: 'Ekosistem dan Rantai Makanan',
      fileUrl: 'https://firebasestorage.example.com/materials/ekosistem.pdf',
      fileType: 'pdf',
      summary: 'Ekosistem adalah kesatuan interaksi timbal balik antara makhluk hidup dengan lingkungannya. Komponen ekosistem terdiri atas biotik (makhluk hidup) dan abiotik (benda tak hidup). Rantai makanan menggambarkan jalur transfer energi dari satu organisme ke organisme lain melalui peristiwa makan dan dimakan dengan urutan tertentu: produsen, konsumen tingkat I, konsumen tingkat II, hingga pengurai (dekomposer). Gangguan pada salah satu rantai berisiko merusak keseimbangan seluruh ekosistem.',
      isPublished: false,
      createdAt: DateTime.now(),
      aiProcessingStatus: 'done',
      topics: ['Komponen Biotik Abiotik', 'Tingkatan Rantai Makanan', 'Keseimbangan Ekosistem'],
      learningResources: [],
    );
    await _saveData('materials', mat4.materialId, mat4.toJson(), mat4.toFirestore());

    // 5. ASESMEN (Quick Check & Quiz Utama)
    final Map<String, List<QuestionModel>> materialQuestions = {
      'mat_aljabar': [
        QuestionModel(
          questionId: 'q_alj_1',
          questionText: 'Bentuk sederhana dari 3x + 5y - 2x + y adalah...',
          options: ['A. x + 6y', 'B. 5x + 6y', 'C. x + 4y', 'D. 5x + 4y'],
          correctAnswerIndex: 0,
          topicTag: 'Pengertian Aljabar',
        ),
        QuestionModel(
          questionId: 'q_alj_2',
          questionText: 'Koefisien dari variabel x pada bentuk aljabar 2x^2 - 5x + 8 adalah...',
          options: ['A. 2', 'B. -5', 'C. 5', 'D. 8'],
          correctAnswerIndex: 1,
          topicTag: 'Pengertian Aljabar',
        ),
        QuestionModel(
          questionId: 'q_alj_3',
          questionText: 'Andi membeli 3 buah buku tulis. Jika harga satu buku tulis dinyatakan dengan p rupiah, maka bentuk aljabar untuk total harga belanjaan Andi adalah...',
          options: ['A. 3 + p', 'B. p / 3', 'C. 3p', 'D. p - 3'],
          correctAnswerIndex: 2,
          topicTag: 'Soal Cerita Aljabar',
        ),
        QuestionModel(
          questionId: 'q_alj_4',
          questionText: 'Hasil perkalian dari (x + 2)(x + 3) adalah...',
          options: ['A. x^2 + 5x + 6', 'B. x^2 + 6x + 5', 'C. x^2 + 5x + 5', 'D. x^2 + 6'],
          correctAnswerIndex: 0,
          topicTag: 'Operasi Penjumlahan Aljabar',
        ),
        QuestionModel(
          questionId: 'q_alj_5',
          questionText: 'Hasil dari 4a^2b * 3ab^3 adalah...',
          options: ['A. 12a^3b^4', 'B. 12a^2b^3', 'C. 7a^3b^4', 'D. 7a^2b^3'],
          correctAnswerIndex: 0,
          topicTag: 'Operasi Penjumlahan Aljabar',
        ),
        QuestionModel(
          questionId: 'q_alj_6',
          questionText: 'Pada bentuk aljabar 4x - 7, konstanta dari bentuk tersebut adalah...',
          options: ['A. 4', 'B. x', 'C. -7', 'D. 7'],
          correctAnswerIndex: 2,
          topicTag: 'Pengertian Aljabar',
        ),
        QuestionModel(
          questionId: 'q_alj_7',
          questionText: 'Bentuk aljabar untuk kalimat "5 kurangnya dari dua kali umur Budi (y)" adalah...',
          options: ['A. 5 - 2y', 'B. 2y - 5', 'C. 2(y - 5)', 'D. 5y - 2'],
          correctAnswerIndex: 1,
          topicTag: 'Soal Cerita Aljabar',
        ),
        QuestionModel(
          questionId: 'q_alj_8',
          questionText: 'Jumlah dari 8x - 3y dan -2x + 7y adalah...',
          options: ['A. 6x + 4y', 'B. 6x - 10y', 'C. 10x + 4y', 'D. 10x - 10y'],
          correctAnswerIndex: 0,
          topicTag: 'Operasi Penjumlahan Aljabar',
        ),
        QuestionModel(
          questionId: 'q_alj_9',
          questionText: 'Nilai dari bentuk aljabar 3a + 2b jika a = 4 dan b = -1 adalah...',
          options: ['A. 14', 'B. 10', 'C. 12', 'D. 8'],
          correctAnswerIndex: 1,
          topicTag: 'Pengertian Aljabar',
        ),
        QuestionModel(
          questionId: 'q_alj_10',
          questionText: 'Suatu persegi panjang berukuran panjang (3x + 2) cm dan lebar (x - 1) cm. Luas persegi panjang tersebut adalah...',
          options: ['A. 3x^2 - x - 2 cm^2', 'B. 3x^2 + x - 2 cm^2', 'C. 3x^2 - 2 cm^2', 'D. 3x^2 + 5x - 2 cm^2'],
          correctAnswerIndex: 0,
          topicTag: 'Soal Cerita Aljabar',
        ),
      ],
      'mat_persamaan_linear': [
        QuestionModel(
          questionId: 'q_plsv_1',
          questionText: 'Penyelesaian dari persamaan x + 5 = 12 adalah...',
          options: ['A. x = 5', 'B. x = 7', 'C. x = 17', 'D. x = 12'],
          correctAnswerIndex: 1,
          topicTag: 'Definisi PLSV',
        ),
        QuestionModel(
          questionId: 'q_plsv_2',
          questionText: 'Nilai y yang memenuhi persamaan 3y - 4 = 11 adalah...',
          options: ['A. y = 5', 'B. y = 3', 'C. y = 15', 'D. y = 4'],
          correctAnswerIndex: 0,
          topicTag: 'Penyelesaian Ruas Seimbang PLSV',
        ),
        QuestionModel(
          questionId: 'q_plsv_3',
          questionText: 'Umur Ayah adalah 3 kali umur Roni. Jika jumlah umur mereka adalah 48 tahun, model persamaan linear yang sesuai adalah...',
          options: ['A. x + 3x = 48', 'B. 3x = 48', 'C. x - 3x = 48', 'D. x + 3 = 48'],
          correctAnswerIndex: 0,
          topicTag: 'Penerapan PLSV dalam Kehidupan',
        ),
      ],
      'mat_tata_surya': [
        QuestionModel(
          questionId: 'q_solar_1',
          questionText: 'Planet terdekat dari Matahari dalam sistem tata surya kita adalah...',
          options: ['A. Venus', 'B. Merkurius', 'C. Mars', 'D. Bumi'],
          correctAnswerIndex: 1,
          topicTag: 'Karakteristik Matahari & Planet',
        ),
        QuestionModel(
          questionId: 'q_solar_2',
          questionText: 'Planet dalam tata surya yang terkenal memiliki cincin paling indah dan besar adalah...',
          options: ['A. Yupiter', 'B. Neptunus', 'C. Saturnus', 'D. Uranus'],
          correctAnswerIndex: 2,
          topicTag: 'Karakteristik Matahari & Planet',
        ),
        QuestionModel(
          questionId: 'q_solar_3',
          questionText: 'Gaya gravitasi matahari memengaruhi orbit planet agar tetap berada pada jalurnya. Orbit planet berbentuk...',
          options: ['A. Bulat sempurna', 'B. Elips', 'C. Spiral', 'D. Parabola'],
          correctAnswerIndex: 1,
          topicTag: 'Gaya Gravitasi Planet',
        ),
      ]
    };

    // Buat Quick Check & Kuis Utama
    for (final entry in materialQuestions.entries) {
      final matId = entry.key;
      final questions = entry.value;
      final classId = matId.startsWith('mat_') ? class1.classId : class2.classId;

      // 5a. Quick Check (Ambil 3 Soal Teratas)
      final qc = AssessmentModel(
        assessmentId: 'qc_$matId',
        materialId: matId,
        classId: classId,
        type: 'quick_check',
        isPublished: true,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        durationMinutes: 30,
        questions: questions.take(3).toList(),
      );
      await _saveData('assessments', qc.assessmentId, qc.toJson(), qc.toJson());

      // 5b. Kuis Utama (Isi full soal untuk kuis utama)
      final quizUtama = AssessmentModel(
        assessmentId: 'qu_$matId',
        materialId: matId,
        classId: classId,
        type: 'quiz_utama',
        isPublished: true,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        durationMinutes: 30,
        questions: questions,
      );
      await _saveData('assessments', quizUtama.assessmentId, quizUtama.toJson(), quizUtama.toJson());
    }

    // 6. LOG AKTIVITAS MEMBACA SISWA & 7. HASIL KUIS UTAMA SISWA & 8. DIAGNOSIS KOMPETENSI
    // Untuk 10 siswa di kelas Matematika VII-A
    final List<Map<String, dynamic>> mockProgresses = [];
    final List<Map<String, dynamic>> mockActivities = [];
    final List<Map<String, dynamic>> mockResults = [];
    final List<Map<String, dynamic>> mockCompetencies = [];

    for (int i = 0; i < 10; i++) {
      final studentId = 'siswa_${i + 1}';
      final studentName = studentNames[i];

      // Definisikan kategori fokus belajar
      int readSec, idleSec, tabSwitches, focusScore, quizScore;
      List<String> strengths, weaknesses;

      if (i < 3) {
        // Fokus Tinggi (3 Siswa)
        readSec = 900 + (i * 100);
        idleSec = 10 + (i * 10);
        tabSwitches = i % 2;
        focusScore = 88 + (i * 4);
        quizScore = 90 + (i * 5); // 90 - 100
        strengths = ['Operasi Aljabar', 'Substitusi Variabel'];
        weaknesses = ['Soal Cerita Aljabar'];
      } else if (i < 7) {
        // Fokus Sedang (4 Siswa)
        readSec = 600 + (i * 50);
        idleSec = 60 + (i * 20);
        tabSwitches = 2 + (i % 2);
        focusScore = 65 + (i * 3);
        quizScore = 60 + ((i - 3) * 5); // 60 - 80
        strengths = ['Penjumlahan Suku'];
        weaknesses = ['Perkalian Variabel', 'Soal Cerita Aljabar'];
      } else {
        // Fokus Rendah (3 Siswa)
        readSec = 180 + (i * 40);
        idleSec = 200 + (i * 50);
        tabSwitches = 5 + (i - 7);
        focusScore = 25 + (i * 2);
        quizScore = 30 + ((i - 7) * 10); // 30 - 50
        strengths = [];
        weaknesses = ['Operasi Aljabar', 'Substitusi Variabel', 'Soal Cerita Aljabar'];
      }

      // Progress Pembelajaran
      final progress = {
        'studentId': studentId,
        'materialId': 'mat_aljabar',
        'isReadingCompleted': true,
        'readingCompletedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'isQuickCheckPassed': true,
        'quickCheckPassedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'cooldownUntil': null,
        'totalAttempts': 1
      };
      mockProgresses.add(progress);
      await _saveData('student_progress', '${studentId}_mat_aljabar', progress, progress);

      // Aktivitas Membaca (activities)
      final activity = {
        'activityId': 'act_${studentId}_aljabar',
        'studentId': studentId,
        'materialId': 'mat_aljabar',
        'readDurationSec': readSec,
        'idleTimeSec': idleSec,
        'tabSwitches': tabSwitches,
        'focusScore': focusScore,
        'isCompleted': true,
        'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()
      };
      mockActivities.add(activity);
      await _saveData('activities', activity['activityId'] as String, activity, activity);

      // Hasil Kuis Utama (quiz_results)
      final answers = <String, dynamic>{};
      final questions = materialQuestions['mat_aljabar']!;
      for (int qIdx = 0; qIdx < questions.length; qIdx++) {
        final q = questions[qIdx];
        final isCorrect = qIdx < (quizScore / 10).round();
        answers[q.questionId] = {
          'questionId': q.questionId,
          'questionText': q.questionText,
          'selectedAnswerIndex': isCorrect ? q.correctAnswerIndex : (q.correctAnswerIndex + 1) % 4,
          'correctAnswerIndex': q.correctAnswerIndex,
          'isCorrect': isCorrect,
        };
      }

      final quizResult = {
        'resultId': 'res_${studentId}_aljabar',
        'studentId': studentId,
        'studentName': studentName,
        'assessmentId': 'qu_mat_aljabar',
        'materialId': 'mat_aljabar',
        'score': quizScore,
        'answers': answers,
        'submittedAt': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      };
      mockResults.add(quizResult);
      await _saveData('quiz_results', quizResult['resultId'] as String, quizResult, quizResult);

      // Diagnosis Kompetensi (student_competencies)
      final comp = {
        'competencyId': 'comp_${studentId}_aljabar',
        'studentId': studentId,
        'classId': class1.classId,
        'materialId': 'mat_aljabar',
        'strengths': strengths,
        'weaknesses': weaknesses,
        'focusScore': focusScore,
        'averageScore': quizScore.toDouble(),
        'teacherNarrative': 'Siswa menunjukkan performa belajar yang sesuai dengan tingkat kefokusan membaca materi.',
        'studentNarrative': 'Pertahankan gaya belajarmu!',
        'parentNarrative': 'Mohon bimbing anak Anda untuk belajar lebih giat.',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      mockCompetencies.add(comp);
      await _saveData('student_competencies', comp['competencyId'] as String, comp, comp);
    }

    // 9. DATA INTERVENSI AI (interventions)
    final intervention = InterventionModel(
      interventionId: 'int_mat_aljabar',
      classId: class1.classId,
      materialId: 'mat_aljabar',
      summaryAlert: '60% siswa masih kesulitan memahami Soal Cerita Aljabar',
      recommendations: const [
        'Ulangi penjelasan Soal Cerita Aljabar menggunakan media visual selama 20 menit',
        'Berikan 5 soal latihan tambahan bertahap dari mudah ke sulit',
        'Gunakan contoh kehidupan sehari-hari untuk menjelaskan konsep variabel'
      ],
      individualInterventions: [
        IndividualInterventionModel(studentId: 'siswa_8', studentName: 'Hadi Nugroho', message: 'Hadi perlu latihan tambahan pada visualisasi variabel aljabar.'),
        IndividualInterventionModel(studentId: 'siswa_9', studentName: 'Indah Sari', message: 'Indah memerlukan bimbingan khusus menerjemahkan soal cerita ke kalimat matematika.'),
        IndividualInterventionModel(studentId: 'siswa_10', studentName: 'Joko Susanto', message: 'Joko disarankan mempelajari kembali video konsep variabel di modul.')
      ],
    );
    await _saveData('interventions', intervention.interventionId, intervention.toJson(), intervention.toJson());

    // 10. DATA REKOMENDASI BAKAT (talent_recommendations)
    final talent1 = TalentRecommendationModel(
      recommendationId: 'tr_adi',
      teacherId: teacherUid,
      studentId: 'siswa_1',
      studentName: 'Adi Pratama',
      recommendedField: 'olimpiade',
      confidenceScore: 0.92,
      reasoning: 'Konsisten mendapat nilai di atas 90 pada topik logika dan aljabar selama 4 minggu berturut-turut...',
    );
    await _saveData('talent_recommendations', talent1.recommendationId, talent1.toJson(), talent1.toJson());

    final talent2 = TalentRecommendationModel(
      recommendationId: 'tr_citra',
      teacherId: teacherUid,
      studentId: 'siswa_3',
      studentName: 'Citra Dewi',
      recommendedField: 'sains',
      confidenceScore: 0.85,
      reasoning: 'Menunjukkan pemahaman mendalam pada materi IPA ekosistem...',
    );
    await _saveData('talent_recommendations', talent2.recommendationId, talent2.toJson(), talent2.toJson());

    final talent3 = TalentRecommendationModel(
      recommendationId: 'tr_fajar',
      teacherId: teacherUid,
      studentId: 'siswa_6',
      studentName: 'Fajar Hidayat',
      recommendedField: 'informatika',
      confidenceScore: 0.78,
      reasoning: 'Kecepatan penyelesaian soal logika di atas rata-rata kelas...',
    );
    await _saveData('talent_recommendations', talent3.recommendationId, talent3.toJson(), talent3.toJson());

    // Tambah data kompetensi kelas untuk fl_chart F-05
    final classComp = CompetencyModel(
      classId: class1.classId,
      averageScore: 66.5,
      highestMistakeTopics: [
        MistakeTopicModel(topic: 'Soal Cerita Aljabar', errorRate: 0.60),
        MistakeTopicModel(topic: 'Operasi Penjumlahan Aljabar', errorRate: 0.40),
        MistakeTopicModel(topic: 'Pengertian Aljabar', errorRate: 0.15),
      ],
      competencyMastery: const {
        'Pemahaman Dasar': 0.85,
        'Kalkulasi': 0.70,
        'Analisis Logika': 0.55,
        'Penerapan Soal': 0.40,
        'Konsistensi': 0.75,
      },
    );
    await _saveData('competency_dashboards', classComp.classId, classComp.toJson(), classComp.toJson());

    // Tambah analytics history untuk F-07
    final mockAnalytics = {
      'classId': class1.classId,
      'weeklyAverage': [
        {'week': 'Minggu 1', 'score': 62.0},
        {'week': 'Minggu 2', 'score': 65.5},
        {'week': 'Minggu 3', 'score': 64.0},
        {'week': 'Minggu 4', 'score': 66.5},
      ],
      'materialStats': [
        {
          'materialId': 'mat_aljabar',
          'materialTitle': 'Aljabar Dasar',
          'avgReadDurationSec': 740,
          'avgQuizScore': 66.5
        },
        {
          'materialId': 'mat_persamaan_linear',
          'materialTitle': 'Persamaan Linear Satu Variabel',
          'avgReadDurationSec': 620,
          'avgQuizScore': 72.0
        }
      ]
    };
    await _saveData('class_analytics', classComp.classId, mockAnalytics, mockAnalytics);

    debugPrint('=== SEEDING DATA DUMMY GURU SELESAI ===');
  }

  static Future<void> clearAll() async {
    debugPrint('=== MEMBERSIHKAN DATA DUMMY GURU ===');
    
    if (_isMockMode) {
      await MockDb.init();
      // Hapus data mock local
      await MockDb.remove('users');
      await MockDb.remove('classes');
      await MockDb.remove('materials');
      await MockDb.remove('assessments');
      await MockDb.remove('student_progress');
      await MockDb.remove('activities');
      await MockDb.remove('quiz_results');
      await MockDb.remove('student_competencies');
      await MockDb.remove('interventions');
      await MockDb.remove('talent_recommendations');
      await MockDb.remove('competency_dashboards');
      await MockDb.remove('class_analytics');
      await MockDb.remove('current_user_uid');
      debugPrint('=== PEMBERSIHAN MOCK DB SELESAI ===');
      return;
    }

    // Pembersihan Firestore
    final firestore = FirebaseFirestore.instance;
    final collections = [
      'users', 'classes', 'materials', 'assessments', 'student_progress',
      'activities', 'quiz_results', 'student_competencies', 'interventions',
      'talent_recommendations', 'competency_dashboards', 'class_analytics'
    ];

    for (final col in collections) {
      final snapshot = await firestore.collection(col).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
    debugPrint('=== PEMBERSIHAN FIRESTORE SELESAI ===');
  }

  static Future<void> _saveData(
    String collection,
    String id,
    Map<String, dynamic> localData,
    Map<String, dynamic> firestoreData,
  ) async {
    if (_isMockMode) {
      await MockDb.init();
      await MockDb.save(collection, id, localData);
    } else {
      await FirebaseFirestore.instance.collection(collection).doc(id).set(firestoreData);
    }
  }
}
