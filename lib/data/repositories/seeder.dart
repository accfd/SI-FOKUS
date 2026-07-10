import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'mock_db.dart';

bool get isMockMode {
  try {
    return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
  } catch (_) {
    return true;
  }
}

class DatabaseSeeder {
  static Future<void> seedAll() async {
    if (isMockMode) {
      // 1. Teacher
      final teacherUid = 'mock_teacher_123';
      await MockDb.save('users', teacherUid, {
        'uid': teacherUid,
        'name': 'Drs. Fuadi Hidayat, M.Pd.',
        'email': 'guru@sifokus.sch.id',
        'role': 'guru',
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // 2. Student (Muhammad Rizky)
      final studentUid = 'mock_student_123';
      await MockDb.save('users', studentUid, {
        'uid': studentUid,
        'name': 'Muhammad Rizky',
        'email': 'siswa@sifokus.sch.id',
        'role': 'siswa',
        'parentAccessCode': 'RIZKY9',
        'xp': 450,
        'level': 3,
        'unlockedBadges': ['Kuis Master', 'Pembaca Cepat', 'Peringkat 1'],
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 3. Parent
      final parentUid = 'mock_parent_123';
      await MockDb.save('users', parentUid, {
        'uid': parentUid,
        'name': 'Heri Prasetyo (Orang Tua Rizky)',
        'email': 'ortu@sifokus.sch.id',
        'role': 'orang_tua',
        'linkedStudentUid': studentUid,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 4. Other 34 students
      final studentNames = [
        "Aditya Pratama", "Budi Santoso", "Citra Lestari", "Dewi Handayani",
        "Eko Prasetyo", "Farhan Hidayat", "Gita Permata", "Hendra Wijaya",
        "Indah Sari", "Joko Susilo", "Kartika Putri", "Lukman Hakim",
        "Mega Utami", "Naufal Rizqi", "Olivia Natalia", "Putra Ramadhan",
        "Qori Aina", "Rian Hidayat", "Siti Rahmawati", "Teguh Wibowo",
        "Utami Ningsih", "Vina Amelia", "Wahyu Hidayat", "Yayan Ruhiyan",
        "Zaki Mubarak", "Ahmad Fauzi", "Annisa Fitri", "Bayu Segara",
        "Dian Lestari", "Fajar Siddiq", "Halimah Sya'diah", "Irfan Maulana",
        "Lilis Suryani", "Nurul Hidayah"
      ];

      List<String> allStudentUids = [studentUid];

      for (int i = 0; i < studentNames.length; i++) {
        final sUid = 'siswa_seeded_${i + 1}';
        allStudentUids.add(sUid);
        int level = 1 + (i % 3);
        int xp = 100 + (i * 15) % 400;

        await MockDb.save('users', sUid, {
          'uid': sUid,
          'name': studentNames[i],
          'email': 'siswa_${i + 1}@sifokus.sch.id',
          'role': 'siswa',
          'parentAccessCode': 'MOCK${100 + i}',
          'xp': xp,
          'level': level,
          'unlockedBadges': i % 3 == 0 ? ['Kuis Master'] : [],
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      // 5. Class
      await MockDb.save('classes', 'class_x_biologi', {
        'classId': 'class_x_biologi',
        'className': 'Kelas X Biologi 1',
        'classCode': 'BIO10REG',
        'subjectName': 'Biologi',
        'teacherId': teacherUid,
        'studentUids': allStudentUids,
      });

      // 6. 6 Materials
      final kdTitles = [
        "KD 3.1: Ruang Lingkup Biologi",
        "KD 3.2: Keanekaragaman Hayati",
        "KD 3.3: Klasifikasi Makhluk Hidup",
        "KD 3.4: Virus",
        "KD 3.5: Bakteri (Archaebacteria & Eubacteria)",
        "KD 3.6: Fungi (Jamur)"
      ];

      final kdSummaries = [
        "Materi ini membahas tentang kerja ilmiah, tingkat organisasi kehidupan (molekul, sel, jaringan, organ, sistem organ, individu, populasi, komunitas, ekosistem, bioma), cabang-cabang ilmu biologi, serta keselamatan kerja di laboratorium.",
        "Membahas tingkat keanekaragaman hayati (gen, jenis, ekosistem), keanekaragaman hayati Indonesia (zona Oriental, Australian, peralihan), ancaman kepunahan, dan upaya pelestarian in-situ maupun ex-situ.",
        "Membahas prinsip-prinsip klasifikasi makhluk hidup menggunakan sistem tata nama binomial (binomial nomenclature), kunci determinasi, kladogram, serta pengenalan sistem klasifikasi 5 kingdom.",
        "Membahas ciri-ciri virus (aseluler, mikroskopis, hanya bereplikasi di sel inang), struktur virus (kapsid, asam nukleat DNA/RNA), siklus litik dan lisogenik, serta penyakit-penyakit yang disebabkan oleh virus pada manusia, hewan, dan tumbuhan.",
        "Membahas perbedaan Archaebacteria dan Eubacteria, struktur sel bakteri (dinding sel peptidoglikan, membran, ribosom, plasmid), reproduksi bakteri (konjugasi, transduksi, transformasi), serta bakteri menguntungkan dan merugikan dalam kehidupan manusia.",
        "Membahas ciri-ciri umum fungi (eukariotik, heterotrof absorptif, dinding sel kitin), struktur tubuh hifa dan miselium, reproduksi seksual/aseksual, klasifikasi jamur (Zygomycota, Ascomycota, Basidiomycota, Deuteromycota), serta peranan jamur di alam and industri pangan."
      ];

      final kdFiles = [
        "X_Biologi_KD 3.1_Final.pdf",
        "X_Biologi_KD 3.2_Final.pdf",
        "X_Biologi_KD 3.3_Final.pdf",
        "X_Biologi_KD 3.4_Final.pdf",
        "X_Biologi_KD 3.5_Final.pdf",
        "X_Biologi_KD 3.6_Final.pdf"
      ];

      for (int i = 0; i < 5; i++) {
        final materialId = 'mat_kd_3${i + 1}';
        await MockDb.save('materials', materialId, {
          'materialId': materialId,
          'classId': 'class_x_biologi',
          'title': kdTitles[i],
          'fileUrl': 'modul_uji/X_Biologi_KD_3.${i + 1}_Final.pdf',
          'fileType': 'pdf',
          'summary': kdSummaries[i],
          'createdAt': DateTime.now().toIso8601String(),
          'isPublished': true,
          'learningResources': [
            {
              'resourceId': 'res_yt_$materialId',
              'title': 'Video Pembelajaran ${kdTitles[i]}',
              'type': 'youtube',
              'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
            },
            {
              'resourceId': 'res_link_$materialId',
              'title': 'Artikel Wikipedia ${kdTitles[i]}',
              'type': 'link',
              'url': 'https://id.wikipedia.org/wiki/${kdTitles[i].split(": ").last.split(" ").first}'
            }
          ]
        });

        // QC Assessment
        final quickCheckId = 'assess_qc_$materialId';
        final qcQuestions = _getQCQuestions(i);
        await MockDb.save('assessments', quickCheckId, {
          'assessmentId': quickCheckId,
          'materialId': materialId,
          'classId': 'class_x_biologi',
          'type': 'quick_check',
          'startDate': null,
          'endDate': null,
          'durationMinutes': 10,
          'isPublished': true,
          'questions': qcQuestions.map((q) => q.toJson()).toList(),
        });

        // QU Assessment
        final quizUtamaId = 'assess_qu_$materialId';
        final quQuestions = _getQUQuestions(i);
        await MockDb.save('assessments', quizUtamaId, {
          'assessmentId': quizUtamaId,
          'materialId': materialId,
          'classId': 'class_x_biologi',
          'type': 'quiz_utama',
          'startDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'endDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'durationMinutes': 30,
          'isPublished': true,
          'questions': quQuestions.map((q) => q.toJson()).toList(),
        });

        // Interventions
        await MockDb.save('interventions', 'interv_$materialId', {
          'interventionId': 'interv_$materialId',
          'classId': 'class_x_biologi',
          'materialId': materialId,
          'summaryAlert': 'Sekitar ${(20 + i * 8) % 40 + 15}% siswa mengalami kesulitan memahami materi utama ${kdTitles[i].split(": ").last}.',
          'recommendations': [
            'Jelaskan kembali topik esensial ${kdTitles[i].split(": ").last} selama 15 menit.',
            'Gunakan peta konsep visual untuk memperjelas alur materi.',
            'Berikan latihan mandiri terarah.'
          ],
          'individualInterventions': [
            {
              'studentId': 'siswa_seeded_1',
              'studentName': 'Aditya Pratama',
              'message': 'Fokus belajar Anda di materi ${kdTitles[i].split(": ").last} harus ditingkatkan. Silakan pelajari kembali kuisnya.'
            },
            {
              'studentId': 'siswa_seeded_2',
              'studentName': 'Budi Santoso',
              'message': 'Luangkan waktu untuk membaca rangkuman PDF yang ada di dalam menu materi.'
            }
          ]
        });
      }

      // Recommendations
      await MockDb.save('talent_recommendations', 'rec_aditya', {
        'recommendationId': 'rec_aditya',
        'teacherId': teacherUid,
        'studentId': 'siswa_seeded_1',
        'studentName': 'Aditya Pratama',
        'recommendedField': 'olimpiade',
        'confidenceScore': 0.94,
        'reasoning': 'Aditya memiliki pemahaman analitis yang sangat mendalam pada konsep klasifikasi makhluk hidup dan virus, dibuktikan dengan nilai kuis 100 berturut-turut.'
      });
      await MockDb.save('talent_recommendations', 'rec_citra', {
        'recommendationId': 'rec_citra',
        'teacherId': teacherUid,
        'studentId': 'siswa_seeded_3',
        'studentName': 'Citra Lestari',
        'recommendedField': 'sains',
        'confidenceScore': 0.88,
        'reasoning': 'Citra sangat tekun dalam mengamati detail materi praktikum mikrobiologi pada bakteri dan fungi. Ia memiliki bakat riset yang menjanjikan.'
      });
      await MockDb.save('talent_recommendations', 'rec_rizky', {
        'recommendationId': 'rec_rizky',
        'teacherId': teacherUid,
        'studentId': studentUid,
        'studentName': 'Muhammad Rizky',
        'recommendedField': 'informatika',
        'confidenceScore': 0.85,
        'reasoning': 'Rizky menunjukkan logika berpikir komputasional yang runtut saat menganalisis alur dikotomis kunci determinasi makhluk hidup di KD 3.3.'
      });

      // Analytics
      await MockDb.save('analytics', 'class_x_biologi', {
        'classId': 'class_x_biologi',
        'quizTrends': [
          {'quizName': 'Kuis KD 3.1', 'averageScore': 78.5},
          {'quizName': 'Kuis KD 3.2', 'averageScore': 81.2},
          {'quizName': 'Kuis KD 3.3', 'averageScore': 74.0},
          {'quizName': 'Kuis KD 3.4', 'averageScore': 82.5},
          {'quizName': 'Kuis KD 3.5', 'averageScore': 71.8},
          {'quizName': 'Kuis KD 3.6', 'averageScore': 85.0},
        ],
        'readingStats': [
          {
            'moduleTitle': 'KD 3.1 Ruang Lingkup Biologi',
            'avgReadingMinutes': 25.5,
            'avgQuizScore': 78.5
          },
          {
            'moduleTitle': 'KD 3.2 Keanekaragaman Hayati',
            'avgReadingMinutes': 32.0,
            'avgQuizScore': 81.2
          },
          {
            'moduleTitle': 'KD 3.3 Klasifikasi Makhluk Hidup',
            'avgReadingMinutes': 40.5,
            'avgQuizScore': 74.0
          },
          {
            'moduleTitle': 'KD 3.4 Virus',
            'avgReadingMinutes': 28.0,
            'avgQuizScore': 82.5
          },
          {
            'moduleTitle': 'KD 3.5 Bakteri (Archaebacteria & Eubacteria)',
            'avgReadingMinutes': 45.0,
            'avgQuizScore': 71.8
          },
          {
            'moduleTitle': 'KD 3.6 Fungi (Jamur)',
            'avgReadingMinutes': 30.0,
            'avgQuizScore': 85.0
          }
        ],
        'studentSummaries': [
          {
            'studentId': studentUid,
            'studentName': 'Muhammad Rizky',
            'avgQuizScore': 88.5,
            'completedModulesCount': 6
          },
          {
            'studentId': 'siswa_seeded_1',
            'studentName': 'Aditya Pratama',
            'avgQuizScore': 94.0,
            'completedModulesCount': 6
          },
          {
            'studentId': 'siswa_seeded_2',
            'studentName': 'Budi Santoso',
            'avgQuizScore': 68.2,
            'completedModulesCount': 5
          },
          {
            'studentId': 'siswa_seeded_3',
            'studentName': 'Citra Lestari',
            'avgQuizScore': 85.0,
            'completedModulesCount': 6
          }
        ]
      });
      
      return;
    }

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // 1. Create or login Teacher Auth Account
    String teacherUid = '';
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: 'guru@sifokus.sch.id',
        password: '123456',
      );
      teacherUid = cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final cred = await auth.signInWithEmailAndPassword(
          email: 'guru@sifokus.sch.id',
          password: '123456',
        );
        teacherUid = cred.user!.uid;
      } else {
        rethrow;
      }
    }

    // 2. Create or login Student Auth Account
    String studentUid = '';
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: 'siswa@sifokus.sch.id',
        password: '123456',
      );
      studentUid = cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final cred = await auth.signInWithEmailAndPassword(
          email: 'siswa@sifokus.sch.id',
          password: '123456',
        );
        studentUid = cred.user!.uid;
      } else {
        rethrow;
      }
    }

    // 3. Create or login Parent Auth Account
    String parentUid = '';
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: 'ortu@sifokus.sch.id',
        password: '123456',
      );
      parentUid = cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final cred = await auth.signInWithEmailAndPassword(
          email: 'ortu@sifokus.sch.id',
          password: '123456',
        );
        parentUid = cred.user!.uid;
      } else {
        rethrow;
      }
    }

    // Write profiles to Firestore "users" collection
    // Guru Profile
    await firestore.collection('users').doc(teacherUid).set({
      'uid': teacherUid,
      'name': 'Drs. Fuadi Hidayat, M.Pd.',
      'email': 'guru@sifokus.sch.id',
      'role': 'guru',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Primary Student Profile (linked to 'siswa@sifokus.sch.id')
    await firestore.collection('users').doc(studentUid).set({
      'uid': studentUid,
      'name': 'Muhammad Rizky',
      'email': 'siswa@sifokus.sch.id',
      'role': 'siswa',
      'parentAccessCode': 'RIZKY9',
      'xp': 450,
      'level': 3,
      'unlockedBadges': ['Kuis Master', 'Pembaca Cepat', 'Peringkat 1'],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Parent Profile (linked to 'ortu@sifokus.sch.id' and linked to studentUid)
    await firestore.collection('users').doc(parentUid).set({
      'uid': parentUid,
      'name': 'Heri Prasetyo (Orang Tua Rizky)',
      'email': 'ortu@sifokus.sch.id',
      'role': 'orang_tua',
      'linkedStudentUid': studentUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Generate profiles for the remaining 34 students
    final studentNames = [
      "Aditya Pratama", "Budi Santoso", "Citra Lestari", "Dewi Handayani",
      "Eko Prasetyo", "Farhan Hidayat", "Gita Permata", "Hendra Wijaya",
      "Indah Sari", "Joko Susilo", "Kartika Putri", "Lukman Hakim",
      "Mega Utami", "Naufal Rizqi", "Olivia Natalia", "Putra Ramadhan",
      "Qori Aina", "Rian Hidayat", "Siti Rahmawati", "Teguh Wibowo",
      "Utami Ningsih", "Vina Amelia", "Wahyu Hidayat", "Yayan Ruhiyan",
      "Zaki Mubarak", "Ahmad Fauzi", "Annisa Fitri", "Bayu Segara",
      "Dian Lestari", "Fajar Siddiq", "Halimah Sya'diah", "Irfan Maulana",
      "Lilis Suryani", "Nurul Hidayah"
    ];

    List<String> allStudentUids = [studentUid];

    for (int i = 0; i < studentNames.length; i++) {
      final sUid = 'siswa_seeded_${i + 1}';
      allStudentUids.add(sUid);
      
      int level = 1 + (i % 3);
      int xp = 100 + (i * 15) % 400;
      
      await firestore.collection('users').doc(sUid).set({
        'uid': sUid,
        'name': studentNames[i],
        'email': 'siswa_${i + 1}@sifokus.sch.id',
        'role': 'siswa',
        'parentAccessCode': 'MOCK${100 + i}',
        'xp': xp,
        'level': level,
        'unlockedBadges': i % 3 == 0 ? ['Kuis Master'] : [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 4. Create Class Document "class_x_biologi"
    await firestore.collection('classes').doc('class_x_biologi').set({
      'classId': 'class_x_biologi',
      'className': 'Kelas X Biologi 1',
      'classCode': 'BIO10REG',
      'subjectName': 'Biologi',
      'teacherId': teacherUid,
      'studentUids': allStudentUids,
    });

    // 5. Create 6 Materials (KD 3.1 s.d. KD 3.6)
    final kdTitles = [
      "KD 3.1: Ruang Lingkup Biologi",
      "KD 3.2: Keanekaragaman Hayati",
      "KD 3.3: Klasifikasi Makhluk Hidup",
      "KD 3.4: Virus",
      "KD 3.5: Bakteri (Archaebacteria & Eubacteria)",
      "KD 3.6: Fungi (Jamur)"
    ];

    final kdSummaries = [
      "Materi ini membahas tentang kerja ilmiah, tingkat organisasi kehidupan (molekul, sel, jaringan, organ, sistem organ, individu, populasi, komunitas, ekosistem, bioma), cabang-cabang ilmu biologi, serta keselamatan kerja di laboratorium.",
      "Membahas tingkat keanekaragaman hayati (gen, jenis, ekosistem), keanekaragaman hayati Indonesia (zona Oriental, Australian, peralihan), ancaman kepunahan, dan upaya pelestarian in-situ maupun ex-situ.",
      "Membahas prinsip-prinsip klasifikasi makhluk hidup menggunakan sistem tata nama binomial (binomial nomenclature), kunci determinasi, kladogram, serta pengenalan sistem klasifikasi 5 kingdom.",
      "Membahas ciri-ciri virus (aseluler, mikroskopis, hanya bereplikasi di sel inang), struktur virus (kapsid, asam nukleat DNA/RNA), siklus litik dan lisogenik, serta penyakit-penyakit yang disebabkan oleh virus pada manusia, hewan, dan tumbuhan.",
      "Membahas perbedaan Archaebacteria dan Eubacteria, struktur sel bakteri (dinding sel peptidoglikan, membran, ribosom, plasmid), reproduksi bakteri (konjugasi, transduksi, transformasi), serta bakteri menguntungkan dan merugikan dalam kehidupan manusia.",
      "Membahas ciri-ciri umum fungi (eukariotik, heterotrof absorptif, dinding sel kitin), struktur tubuh hifa dan miselium, reproduksi seksual/aseksual, klasifikasi jamur (Zygomycota, Ascomycota, Basidiomycota, Deuteromycota), serta peranan jamur di alam dan industri pangan."
    ];

    final kdFiles = [
      "X_Biologi_KD 3.1_Final.pdf",
      "X_Biologi_KD 3.2_Final.pdf",
      "X_Biologi_KD 3.3_Final.pdf",
      "X_Biologi_KD 3.4_Final.pdf",
      "X_Biologi_KD 3.5_Final.pdf",
      "X_Biologi_KD 3.6_Final.pdf"
    ];

    for (int i = 0; i < 5; i++) {
      final materialId = 'mat_kd_3${i + 1}';
      
      await firestore.collection('materials').doc(materialId).set({
        'materialId': materialId,
        'classId': 'class_x_biologi',
        'title': kdTitles[i],
        'fileUrl': 'modul_uji/X_Biologi_KD_3.${i + 1}_Final.pdf',
        'fileType': 'pdf',
        'summary': kdSummaries[i],
        'createdAt': Timestamp.now(),
        'isPublished': true,
        'learningResources': [
          {
            'resourceId': 'res_yt_$materialId',
            'title': 'Video Pembelajaran ${kdTitles[i]}',
            'type': 'youtube',
            'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
          },
          {
            'resourceId': 'res_link_$materialId',
            'title': 'Artikel Wikipedia ${kdTitles[i]}',
            'type': 'link',
            'url': 'https://id.wikipedia.org/wiki/${kdTitles[i].split(": ").last.split(" ").first}'
          }
        ]
      });

      // 6. Create Assessments (Quick Check & Quiz Utama)
      final quickCheckId = 'assess_qc_$materialId';
      final quizUtamaId = 'assess_qu_$materialId';

      final qcQuestions = _getQCQuestions(i);
      await firestore.collection('assessments').doc(quickCheckId).set({
        'assessmentId': quickCheckId,
        'materialId': materialId,
        'classId': 'class_x_biologi',
        'type': 'quick_check',
        'startDate': null,
        'endDate': null,
        'durationMinutes': 10,
        'isPublished': true,
        'questions': qcQuestions.map((q) => q.toJson()).toList(),
      });

      final quQuestions = _getQUQuestions(i);
      await firestore.collection('assessments').doc(quizUtamaId).set({
        'assessmentId': quizUtamaId,
        'materialId': materialId,
        'classId': 'class_x_biologi',
        'type': 'quiz_utama',
        'startDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'durationMinutes': 30,
        'isPublished': true,
        'questions': quQuestions.map((q) => q.toJson()).toList(),
      });

      // 7. Seed Interventions
      await firestore.collection('interventions').doc('interv_$materialId').set({
        'interventionId': 'interv_$materialId',
        'classId': 'class_x_biologi',
        'materialId': materialId,
        'summaryAlert': 'Sekitar ${(20 + i * 8) % 40 + 15}% siswa mengalami kesulitan memahami materi utama ${kdTitles[i].split(": ").last}.',
        'recommendations': [
          'Jelaskan kembali topik esensial ${kdTitles[i].split(": ").last} selama 15 menit.',
          'Gunakan peta konsep visual untuk memperjelas alur materi.',
          'Berikan latihan mandiri terarah.'
        ],
        'individualInterventions': [
          {
            'studentId': 'siswa_seeded_1',
            'studentName': 'Aditya Pratama',
            'message': 'Fokus belajar Anda di materi ${kdTitles[i].split(": ").last} harus ditingkatkan. Silakan pelajari kembali kuisnya.'
          },
          {
            'studentId': 'siswa_seeded_2',
            'studentName': 'Budi Santoso',
            'message': 'Luangkan waktu untuk membaca rangkuman PDF yang ada di dalam menu materi.'
          }
        ]
      });
    }

    // 8. Seed Talent Recommendations
    await firestore.collection('talent_recommendations').doc('rec_aditya').set({
      'recommendationId': 'rec_aditya',
      'teacherId': teacherUid,
      'studentId': 'siswa_seeded_1',
      'studentName': 'Aditya Pratama',
      'recommendedField': 'olimpiade',
      'confidenceScore': 0.94,
      'reasoning': 'Aditya memiliki pemahaman analitis yang sangat mendalam pada konsep klasifikasi makhluk hidup dan virus, dibuktikan dengan nilai kuis 100 berturut-turut.'
    });

    await firestore.collection('talent_recommendations').doc('rec_citra').set({
      'recommendationId': 'rec_citra',
      'teacherId': teacherUid,
      'studentId': 'siswa_seeded_3',
      'studentName': 'Citra Lestari',
      'recommendedField': 'sains',
      'confidenceScore': 0.88,
      'reasoning': 'Citra sangat tekun dalam mengamati detail materi praktikum mikrobiologi pada bakteri dan fungi. Ia memiliki bakat riset yang menjanjikan.'
    });

    await firestore.collection('talent_recommendations').doc('rec_rizky').set({
      'recommendationId': 'rec_rizky',
      'teacherId': teacherUid,
      'studentId': studentUid,
      'studentName': 'Muhammad Rizky',
      'recommendedField': 'informatika',
      'confidenceScore': 0.85,
      'reasoning': 'Rizky menunjukkan logika berpikir komputasional yang runtut saat menganalisis alur dikotomis kunci determinasi makhluk hidup di KD 3.3.'
    });

    // 9. Seed Class Analytics
    await firestore.collection('analytics').doc('class_x_biologi').set({
      'classId': 'class_x_biologi',
      'quizTrends': [
        {'quizName': 'Kuis KD 3.1', 'averageScore': 78.5},
        {'quizName': 'Kuis KD 3.2', 'averageScore': 81.2},
        {'quizName': 'Kuis KD 3.3', 'averageScore': 74.0},
        {'quizName': 'Kuis KD 3.4', 'averageScore': 82.5},
        {'quizName': 'Kuis KD 3.5', 'averageScore': 71.8},
        {'quizName': 'Kuis KD 3.6', 'averageScore': 85.0},
      ],
      'readingStats': [
        {
          'moduleTitle': 'KD 3.1 Ruang Lingkup Biologi',
          'avgReadingMinutes': 25.5,
          'avgQuizScore': 78.5
        },
        {
          'moduleTitle': 'KD 3.2 Keanekaragaman Hayati',
          'avgReadingMinutes': 32.0,
          'avgQuizScore': 81.2
        },
        {
          'moduleTitle': 'KD 3.3 Klasifikasi Makhluk Hidup',
          'avgReadingMinutes': 40.5,
          'avgQuizScore': 74.0
        },
        {
          'moduleTitle': 'KD 3.4 Virus',
          'avgReadingMinutes': 28.0,
          'avgQuizScore': 82.5
        },
        {
          'moduleTitle': 'KD 3.5 Bakteri (Archaebacteria & Eubacteria)',
          'avgReadingMinutes': 45.0,
          'avgQuizScore': 71.8
        },
        {
          'moduleTitle': 'KD 3.6 Fungi (Jamur)',
          'avgReadingMinutes': 30.0,
          'avgQuizScore': 85.0
        }
      ],
      'studentSummaries': [
        {
          'studentId': studentUid,
          'studentName': 'Muhammad Rizky',
          'avgQuizScore': 88.5,
          'completedModulesCount': 6
        },
        {
          'studentId': 'siswa_seeded_1',
          'studentName': 'Aditya Pratama',
          'avgQuizScore': 94.0,
          'completedModulesCount': 6
        },
        {
          'studentId': 'siswa_seeded_2',
          'studentName': 'Budi Santoso',
          'avgQuizScore': 68.2,
          'completedModulesCount': 5
        },
        {
          'studentId': 'siswa_seeded_3',
          'studentName': 'Citra Lestari',
          'avgQuizScore': 85.0,
          'completedModulesCount': 6
        }
      ]
    });
  }

  static List<QuestionModelSeeded> _getQCQuestions(int topicIndex) {
    return _qcBank[topicIndex] ?? [];
  }

  static List<QuestionModelSeeded> _getQUQuestions(int topicIndex) {
    return _quBank[topicIndex] ?? [];
  }

  static final Map<int, List<QuestionModelSeeded>> _qcBank = {
    0: [
      QuestionModelSeeded(
        questionId: 'qc_1_1',
        questionText: 'Manakah di bawah ini yang merupakan contoh cabang biologi yang mempelajari serangga?',
        options: ['Ornitologi', 'Entomologi', 'Mikologi', 'Botani'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qc_1_2',
        questionText: 'Tingkatan organisasi kehidupan dari yang terkecil hingga terbesar yang benar adalah...',
        options: [
          'Sel - Jaringan - Organ - Sistem Organ - Individu',
          'Jaringan - Sel - Organ - Individu - Sistem Organ',
          'Individu - Sel - Organ - Jaringan - Sistem Organ',
          'Sistem Organ - Organ - Jaringan - Sel - Individu'
        ],
        correctAnswerIndex: 0,
      ),
      QuestionModelSeeded(
        questionId: 'qc_1_3',
        questionText: 'Langkah pertama dalam metode ilmiah adalah...',
        options: ['Menyusun hipotesis', 'Melakukan eksperimen', 'Merumuskan masalah', 'Menarik kesimpulan'],
        correctAnswerIndex: 2,
      ),
    ],
    1: [
      QuestionModelSeeded(
        questionId: 'qc_2_1',
        questionText: 'Keanekaragaman yang ditunjukkan oleh perbedaan warna bunga mawar (merah, putih, kuning) merupakan contoh keanekaragaman tingkat...',
        options: ['Spesies', 'Gen', 'Ekosistem', 'Populasi'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qc_2_2',
        questionText: 'Fauna Indonesia yang berada di wilayah peralihan (antara garis Wallace dan Weber) adalah...',
        options: ['Orangutan', 'Anoa dan Komodo', 'Kanguru', 'Harimau Sumatra'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qc_2_3',
        questionText: 'Pelestarian badak bercula satu di Ujung Kulon merupakan contoh pelestarian...',
        options: ['Ex-situ', 'In-situ', 'Kultur jaringan', 'Domestikasi'],
        correctAnswerIndex: 1,
      ),
    ],
    2: [
      QuestionModelSeeded(
        questionId: 'qc_3_1',
        questionText: 'Sistem tata nama ilmiah makhluk hidup yang terdiri dari dua kata disebut...',
        options: ['Kunci Determinasi', 'Kladistik', 'Binomial Nomenclature', 'Taksonomi'],
        correctAnswerIndex: 2,
      ),
      QuestionModelSeeded(
        questionId: 'qc_3_2',
        questionText: 'Urutan takson tumbuhan dari yang tertinggi ke terendah adalah...',
        options: [
          'Kingdom - Divisi - Kelas - Ordo - Famili - Genus - Spesies',
          'Kingdom - Filum - Kelas - Ordo - Famili - Genus - Spesies',
          'Divisi - Kingdom - Ordo - Kelas - Famili - Genus - Spesies',
          'Spesies - Genus - Famili - Ordo - Kelas - Divisi - Kingdom'
        ],
        correctAnswerIndex: 0,
      ),
      QuestionModelSeeded(
        questionId: 'qc_3_3',
        questionText: 'Siapakah ilmuwan yang mengemukakan sistem klasifikasi 5 kingdom?',
        options: ['Robert Whittaker', 'Carl Woese', 'Charles Darwin', 'Gregor Mendel'],
        correctAnswerIndex: 0,
      ),
    ],
    3: [
      QuestionModelSeeded(
        questionId: 'qc_4_1',
        questionText: 'Mengapa virus dikatakan aseluler?',
        options: [
          'Karena ukurannya sangat kecil',
          'Karena tidak memiliki organel dan membran sel',
          'Karena materi genetiknya hanya berupa DNA',
          'Karena memiliki kapsid pelindung'
        ],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qc_4_2',
        questionText: 'Siklus reproduksi virus yang diakhiri dengan integrasi materi genetik virus ke DNA inang tanpa merusaknya langsung disebut...',
        options: ['Siklus litik', 'Siklus lisogenik', 'Siklus adsorpsi', 'Siklus sintesis'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qc_4_3',
        questionText: 'Penyakit pada tanaman kelapa atau tembakau yang menyebabkan bintik kuning disebabkan oleh...',
        options: ['Rhabdovirus', 'TMV (Tobacco Mosaic Virus)', 'Bakteriofag', 'HIV'],
        correctAnswerIndex: 1,
      ),
    ],
    4: [
      QuestionModelSeeded(
        questionId: 'qc_5_1',
        questionText: 'Bakteri yang dinding selnya memiliki peptidoglikan tipis dan berwarna merah pada pewarnaan Gram disebut...',
        options: ['Gram positif', 'Gram negatif', 'Archaebacteria', 'Spiroseta'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qc_5_2',
        questionText: 'Proses perpindahan materi genetik bakteri melalui perantara virus bakteriofag disebut...',
        options: ['Transformasi', 'Transduksi', 'Konjugasi', 'Fusi sel'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qc_5_3',
        questionText: 'Bakteri yang berperan dalam pembuatan yoghurt adalah...',
        options: [
          'Escherichia coli',
          'Lactobacillus bulgaricus',
          'Acetobacter aceti',
          'Clostridium tetani'
        ],
        correctAnswerIndex: 1,
      ),
    ],
    5: [
      QuestionModelSeeded(
        questionId: 'qc_6_1',
        questionText: 'Dinding sel jamur (fungi) tersusun atas zat...',
        options: ['Selulosa', 'Lignin', 'Kitin', 'Peptidoglikan'],
        correctAnswerIndex: 2,
      ),
      QuestionModelSeeded(
        questionId: 'qc_6_2',
        questionText: 'Jamur Tempe (Rhizopus oryzae) termasuk dalam divisi...',
        options: ['Ascomycota', 'Zygomycota', 'Basidiomycota', 'Deuteromycota'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qc_6_3',
        questionText: 'Jamur pembentuk tubuh buah berbentuk payung yang sering dikonsumsi (misal jamur tiram) termasuk divisi...',
        options: ['Zygomycota', 'Ascomycota', 'Basidiomycota', 'Deuteromycota'],
        correctAnswerIndex: 2,
      ),
    ]
  };

  static final Map<int, List<QuestionModelSeeded>> _quBank = {
    0: [
      QuestionModelSeeded(
        questionId: 'qu_1_1',
        questionText: 'Cabang biologi yang mempelajari tentang virus disebut...',
        options: ['Bakteriologi', 'Virologi', 'Mikologi', 'Parasitologi'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_1_2',
        questionText: 'Kumpulan beberapa ekosistem di dunia yang memiliki iklim dan vegetasi dominan yang sama disebut...',
        options: ['Biosfer', 'Bioma', 'Komunitas', 'Populasi'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_1_3',
        questionText: 'Untuk menguji pengaruh pupuk terhadap pertumbuhan tanaman cabai, variabel bebas dalam penelitian tersebut adalah...',
        options: ['Jenis tanaman cabai', 'Tinggi tanaman cabai', 'Jenis dan dosis pupuk', 'Intensitas cahaya matahari'],
        correctAnswerIndex: 2,
      ),
      QuestionModelSeeded(
        questionId: 'qu_1_4',
        questionText: 'Langkah metode ilmiah yang dilakukan setelah merumuskan masalah adalah...',
        options: ['Mengumpulkan data', 'Menyusun hipotesis', 'Melakukan eksperimen', 'Menyusun laporan'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_1_5',
        questionText: 'Cabang ilmu biologi yang sangat penting dalam pemuliaan tanaman dan mempelajari sifat warisan induk adalah...',
        options: ['Ekologi', 'Taksonomi', 'Genetika', 'Fisiologi'],
        correctAnswerIndex: 2,
      ),
    ],
    1: [
      QuestionModelSeeded(
        questionId: 'qu_2_1',
        questionText: 'Hutan hujan tropis di Indonesia memiliki keanekaragaman hayati tingkat...',
        options: ['Gen', 'Jenis', 'Ekosistem', 'Habiat'],
        correctAnswerIndex: 2,
      ),
      QuestionModelSeeded(
        questionId: 'qu_2_2',
        questionText: 'Garis khayal yang membatasi wilayah fauna tipe Asiatis dengan wilayah peralihan di Indonesia disebut...',
        options: ['Garis Weber', 'Garis Wallace', 'Garis khatulistiwa', 'Garis astronomis'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_2_3',
        questionText: 'Salah satu penyebab utama penurunan keanekaragaman hayati secara global adalah...',
        options: ['Penghijauan kota', 'Eksploitasi berlebih dan fragmentasi habitat', 'Pembuatan taman nasional', 'Penerapan sistem tumpang sari'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_2_4',
        questionText: 'Konservasi harimau sumatera di kebun binatang Ragunan termasuk dalam metode pelestarian...',
        options: ['In-situ', 'Ex-situ', 'Cagar alam', 'Taman nasional'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_2_5',
        questionText: 'Manakah dari flora berikut yang merupakan tanaman endemik Indonesia?',
        options: ['Rafflesia arnoldii', 'Bunga Sakura', 'Pohon Oak', 'Bunga Tulip'],
        correctAnswerIndex: 0,
      ),
    ],
    2: [
      QuestionModelSeeded(
        questionId: 'qu_3_1',
        questionText: 'Dalam tata nama ganda (Binomial Nomenclature), kata pertama menunjukkan tingkatan...',
        options: ['Spesies', 'Genus', 'Famili', 'Ordo'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_3_2',
        questionText: 'Tujuan utama dilakukannya klasifikasi makhluk hidup adalah...',
        options: [
          'Memberi nama setiap makhluk hidup',
          'Menentukan manfaat setiap makhluk hidup',
          'Mempermudah mempelajari keanekaragaman makhluk hidup',
          'Mencari hubungan kekerabatan yang sangat jauh'
        ],
        correctAnswerIndex: 2,
      ),
      QuestionModelSeeded(
        questionId: 'qu_3_3',
        questionText: 'Kunci analisis yang berisi sejumlah pernyataan berpasangan (dikotomis) untuk mengidentifikasi organisme disebut...',
        options: ['Kunci determinasi', 'Kladogram', 'Silsilah keluarga', 'Dendrogram'],
        correctAnswerIndex: 0,
      ),
      QuestionModelSeeded(
        questionId: 'qu_3_4',
        questionText: 'Makhluk hidup eukariotik, bersel banyak, heterotrof, dan aktif bergerak dimasukkan dalam kingdom...',
        options: ['Plantae', 'Fungi', 'Animalia', 'Protista'],
        correctAnswerIndex: 2,
      ),
      QuestionModelSeeded(
        questionId: 'qu_3_5',
        questionText: 'Diagram yang menggambarkan hubungan kekerabatan evolusioner antar takson berdasarkan kesamaan karakter disebut...',
        options: ['Dendrogram', 'Kladogram', 'Silsilah takson', 'Kunci determinasi'],
        correctAnswerIndex: 1,
      ),
    ],
    3: [
      QuestionModelSeeded(
        questionId: 'qu_4_1',
        questionText: 'Struktur luar virus yang membungkus materi genetik (DNA/RNA) dan tersusun atas kapsomer disebut...',
        options: ['Membran sel', 'Kapsid', 'Dinding sel', 'Selubung lipoprotein'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_4_2',
        questionText: 'Pada siklus litik, tahap pelepasan virus-virus baru yang matang keluar dari sel inang dinamakan tahap...',
        options: ['Adsorpsi', 'Penetrasi', 'Lisis', 'Perakitan'],
        correctAnswerIndex: 2,
      ),
      QuestionModelSeeded(
        questionId: 'qu_4_3',
        questionText: 'Virus penyebab pandemi global Covid-19 memiliki materi genetik berupa...',
        options: ['DNA utas ganda', 'RNA utas tunggal', 'DNA utas tunggal', 'RNA utas ganda'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_4_4',
        questionText: 'Penggunaan virus yang menguntungkan dalam bioteknologi contohnya adalah...',
        options: ['Pembuatan antibiotik', 'Pembuatan vaksin', 'Fermentasi makanan', 'Pembasmian hama ulat secara alami'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_4_5',
        questionText: 'Bakteriofag adalah virus yang menyerang...',
        options: ['Manusia', 'Hewan', 'Bakteri', 'Tumbuhan'],
        correctAnswerIndex: 2,
      ),
    ],
    4: [
      QuestionModelSeeded(
        questionId: 'qu_5_1',
        questionText: 'Salah satu perbedaan mendasar antara Archaebacteria dan Eubacteria adalah...',
        options: [
          'Archaebacteria memiliki membran inti sel',
          'Dinding sel Eubacteria mengandung peptidoglikan',
          'Archaebacteria berkembang biak dengan spora',
          'Eubacteria hidup di tempat yang sangat ekstrem'
        ],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_5_2',
        questionText: 'Bakteri yang berbentuk bola bergandengan menyerupai rantai disebut...',
        options: ['Staphylococcus', 'Streptococcus', 'Diplococcus', 'Sarkina'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_5_3',
        questionText: 'Metode transfer materi genetik bakteri secara langsung melalui kontak fisik jembatan konjugasi disebut...',
        options: ['Konjugasi', 'Transduksi', 'Transformasi', 'Miosis'],
        correctAnswerIndex: 0,
      ),
      QuestionModelSeeded(
        questionId: 'qu_5_4',
        questionText: 'Bakteri anaerob yang memproduksi gas metana dari zat organik di lingkungan ekstrem disebut kelompok...',
        options: ['Halofil ekstrem', 'Termofil ekstrem', 'Metanogen', 'Asidofil ekstrem'],
        correctAnswerIndex: 2,
      ),
      QuestionModelSeeded(
        questionId: 'qu_5_5',
        questionText: 'Bakteri Rhizobium leguminosarum menguntungkan dalam pertanian karena...',
        options: [
          'Menghasilkan antibiotik penisilin',
          'Mengikat nitrogen bebas di udara bersimbiosis dengan akar kacang-kacangan',
          'Menguraikan limbah plastik',
          'Membantu fermentasi nata de coco'
        ],
        correctAnswerIndex: 1,
      ),
    ],
    5: [
      QuestionModelSeeded(
        questionId: 'qu_6_1',
        questionText: 'Fungi memperoleh nutrisi dengan cara...',
        options: [
          'Fotosintesis (autotrof)',
          'Menyerap zat organik dari lingkungan (heterotrof absorptif)',
          'Menelan zat makanan padat (fagositosis)',
          'Kemosintesis'
        ],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_6_2',
        questionText: 'Hifa pada jamur yang bercabang-cabang membentuk jaringan anyaman disebut...',
        options: ['Spora', 'Miselium', 'Septum', 'Basidium'],
        correctAnswerIndex: 1,
      ),
      QuestionModelSeeded(
        questionId: 'qu_6_3',
        questionText: 'Simbiosis mutualisme antara jamur dengan alga hijau membentuk organisme baru yang disebut...',
        options: ['Mikotoksin', 'Mikoriza', 'Lichen (Lumut kerak)', 'Hifa senositik'],
        correctAnswerIndex: 2,
      ),
      QuestionModelSeeded(
        questionId: 'qu_6_4',
        questionText: 'Jamur Saccharomyces cerevisiae sangat penting dalam pembuatan...',
        options: ['Tempe', 'Kecap', 'Roti dan Tape', 'Yoghurt'],
        correctAnswerIndex: 2,
      ),
      QuestionModelSeeded(
        questionId: 'qu_6_5',
        questionText: 'Divisi jamur yang belum diketahui reproduksi seksualnya sehingga dikelompokkan sebagai jamur tidak sempurna (imperfecti) adalah...',
        options: ['Zygomycota', 'Ascomycota', 'Basidiomycota', 'Deuteromycota'],
        correctAnswerIndex: 3,
      ),
    ]
  };
}

class QuestionModelSeeded {
  final String questionId;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  QuestionModelSeeded({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
    };
  }
}
