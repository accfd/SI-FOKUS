import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../../domain/repositories/material_repository.dart';
import '../models/material_model.dart';
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

class MaterialRepositoryImpl implements MaterialRepository {
  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  static final Map<String, List<int>> _mockFileBytes = {};

  static List<int>? getCachedBytes(String materialId) {
    return _mockFileBytes[materialId];
  }

  MaterialRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = isMockMode ? null : (firestore ?? FirebaseFirestore.instance),
        _storage = isMockMode ? null : (storage ?? FirebaseStorage.instance);

  @override
  Future<List<MaterialModel>> fetchClassMaterials(String classId) async {
    if (isMockMode) {
      final allMaterials = await MockDb.getAll('materials');
      return allMaterials
          .where((m) => m['classId'] == classId)
          .map((m) => MaterialModel.fromJson(m))
          .toList();
    }

    final query = await _firestore!
        .collection('materials')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => MaterialModel.fromJson(doc.data())).toList();
  }

  @override
  Future<void> updateMaterialPublishStatus(String materialId, bool isPublished) async {
    if (isMockMode) {
      final data = await MockDb.get('materials', materialId);
      if (data != null) {
        data['isPublished'] = isPublished;
        await MockDb.save('materials', materialId, data);
      }
      return;
    }
    await _firestore!.collection('materials').doc(materialId).update({
      'isPublished': isPublished,
    });
  }

  @override
  Stream<MaterialModel> streamMaterialDetail(String materialId) {
    if (isMockMode) {
      return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
        final data = await MockDb.get('materials', materialId);
        if (data == null) {
          throw Exception('Materi tidak ditemukan.');
        }
        
        final material = MaterialModel.fromJson(data);
        
        // Self-Healing: Jika summary null (karena interupsi refresh/restart), 
        // dan dokumen sudah dibuat lebih dari 20 detik yang lalu (mencegah tabrakan dengan API riil),
        // trigger simulasi AI pemrosesan modul di background
        if (material.summary == null && DateTime.now().difference(material.createdAt).inSeconds > 20) {
          Timer(const Duration(seconds: 2), () async {
            final updatedMaterial = material.copyWith(
              summary: "Dokumen pembelajaran '${material.title}' ini menjelaskan konsep-konsep inti yang mencakup definisi teoretis, struktur formula utama, langkah-langkah penyelesaian matematis, serta studi kasus kontekstual dalam kehidupan sehari-hari secara mendalam dan terarah.",
            );
            
            await MockDb.save('materials', material.materialId, updatedMaterial.toJson());
            
            // Generate Quick Check (3 Soal Biologi Riil)
            final mockQuickCheck = AssessmentModel(
              assessmentId: "qc_${material.materialId}",
              materialId: material.materialId,
              classId: material.classId,
              type: "quick_check",
              questions: [
                QuestionModel(
                  questionId: "q_qc_1",
                  questionText: "Hingga kini penyakit AIDS belum ada obatnya. Penelitian dilakukan oleh para ahli untuk mengetahui aktivitas Virus HIV pada tingkat organisasi kehidupan yaitu...",
                  options: const ["A. Molekul", "B. Sel", "C. Jaringan", "D. Organ", "E. Sistem organ"],
                  correctAnswerIndex: 1,
                  type: "pilihan_ganda",
                  topicTag: "Organisasi Kehidupan",
                ),
                QuestionModel(
                  questionId: "q_qc_2",
                  questionText: "Pembuatan film terkenal Jurassic Park menceritakan kehidupan hewan purba. Cabang ilmu biologi yang paling berperan dalam memodelkan hewan purba tersebut adalah...",
                  options: const ["A. Evolusi", "B. Botani", "C. Zoologi", "D. Palaeontologi", "E. Anatomi"],
                  correctAnswerIndex: 3,
                  type: "pilihan_ganda",
                  topicTag: "Cabang Biologi",
                ),
                QuestionModel(
                  questionId: "q_qc_3",
                  questionText: "Seseorang yang akan menjalani transplantasi organ hati perlu memahami struktur fungsi hati. Studi tersebut dipelajari pada tingkat organisasi...",
                  options: const ["A. Sel", "B. Jaringan", "C. Organ", "D. Sistem organ", "E. Individu"],
                  correctAnswerIndex: 2,
                  type: "pilihan_ganda",
                  topicTag: "Organisasi Kehidupan",
                ),
              ],
              isPublished: true,
            );
            await MockDb.save('assessments', mockQuickCheck.assessmentId, mockQuickCheck.toJson());

            // Generate Kuis Utama (10 Soal Biologi/Aljabar Riil SNBT)
            final mockQuizUtama = AssessmentModel(
              assessmentId: "quiz_${material.materialId}",
              materialId: material.materialId,
              classId: material.classId,
              type: "quiz_utama",
              questions: [
                QuestionModel(
                  questionId: "q_qu_1",
                  questionText: "Berikut merupakan salah satu manfaat penerapan biologi di bidang peternakan secara modern adalah...",
                  options: const [
                    "A. Memperbanyak dengan teknik kultur jaringan",
                    "B. Membuat antibodi monoklonal",
                    "C. Membuat vaksin pencegah penyakit virus SARS",
                    "D. Terapi gen transgenik menghasilkan susu sapi lebih berkualitas",
                    "E. Menghasilkan insulin buatan"
                  ],
                  correctAnswerIndex: 3,
                  type: "pilihan_ganda",
                  topicTag: "Manfaat Biologi",
                ),
                QuestionModel(
                  questionId: "q_qu_2",
                  questionText: "Sekelompok peneliti melakukan pengamatan terhadap perilaku sekumpulan harimau Sumatera (Panthera tigris sumatrae). Tingkat organisasi kehidupan yang diamati adalah...",
                  options: const ["A. Ekosistem", "B. Komunitas", "C. Populasi", "D. Individu", "E. Bioma"],
                  correctAnswerIndex: 2,
                  type: "pilihan_ganda",
                  topicTag: "Organisasi Kehidupan",
                ),
                QuestionModel(
                  questionId: "q_qu_3",
                  questionText: "Seorang peneliti mengamati lingkungan X dan menemukan bahwa banyak bayi terlahir cacat akibat kekurangan gizi serta polusi logam berat. Bidang studi biologi yang mempelajari cacat perkembangan embrio ini adalah...",
                  options: const ["A. Parasitologi", "B. Ginekologi", "C. Teratologi", "D. Genetika", "E. Fisiologi"],
                  correctAnswerIndex: 2,
                  type: "pilihan_ganda",
                  topicTag: "Cabang Biologi",
                ),
                QuestionModel(
                  questionId: "q_qu_4",
                  questionText: "Dalam suatu langkah metode ilmiah, eksperimen atau percobaan dilakukan secara terkontrol untuk menguji...",
                  options: const ["A. Pengumpulan data", "B. Rumusan masalah", "C. Latar belakang", "D. Kesimpulan", "E. Hipotesis"],
                  correctAnswerIndex: 4,
                  type: "pilihan_ganda",
                  topicTag: "Metode Ilmiah",
                ),
                QuestionModel(
                  questionId: "q_qu_5",
                  questionText: "Perilaku yang benar, aman, dan menjaga keselamatan kerja saat berada di dalam laboratorium biologi adalah...",
                  options: const ["A. Membawa bekal makanan", "B. Mengenakan pakaian ketat", "C. Bersikap serius dan tekun", "D. Bersikap gembira dan bercanda", "E. Menggunakan seragam sekolah ketat"],
                  correctAnswerIndex: 2,
                  type: "pilihan_ganda",
                  topicTag: "Keselamatan Kerja",
                ),
                QuestionModel(
                  questionId: "q_qu_6",
                  questionText: "Jika Anda memasuki laboratorium dan melihat simbol botol pecah mengeluarkan cairan korosif, berarti zat tersebut bersifat...",
                  options: const ["A. Korosif", "B. Beracun", "C. Radioaktif", "D. Mudah meledak", "E. Mudah terbakar"],
                  correctAnswerIndex: 0,
                  type: "pilihan_ganda",
                  topicTag: "Keselamatan Kerja",
                ),
                // Soal Majemuk Kompleks
                QuestionModel(
                  questionId: "q_qu_7",
                  questionText: "Tentukan Benar (B) atau Salah (S) untuk pernyataan keselamatan kerja berikut:\n1. Membuang sisa limbah asam pekat langsung ke wastafel diperbolehkan.\n2. Selalu gunakan jas lab kancing lengkap saat berada di laboratorium.",
                  options: const [],
                  correctAnswerIndex: 0,
                  type: "majemuk_kompleks",
                  correctAnswers: const [0, 1],
                  topicTag: "Keselamatan Kerja",
                ),
                QuestionModel(
                  questionId: "q_qu_8",
                  questionText: "Tentukan Benar (B) atau Salah (S) untuk pernyataan tingkat organisasi kehidupan berikut:\n1. Kumpulan sel sejenis yang memiliki bentuk dan fungsi sama disebut jaringan.\n2. Tingkatan organisasi kehidupan tertinggi di biosfer adalah individu tunggal.",
                  options: const [],
                  correctAnswerIndex: 0,
                  type: "majemuk_kompleks",
                  correctAnswers: const [1, 0],
                  topicTag: "Organisasi Kehidupan",
                ),
                // Soal Isian Singkat
                QuestionModel(
                  questionId: "q_qu_9",
                  questionText: "Langkah pertama dalam metode ilmiah setelah mengamati fenomena alam secara seksama adalah merumuskan...",
                  options: const [],
                  correctAnswerIndex: 0,
                  type: "isian_singkat",
                  correctAnswerText: "masalah",
                  topicTag: "Metode Ilmiah",
                ),
                QuestionModel(
                  questionId: "q_qu_10",
                  questionText: "Dugaan awal atau jawaban sementara yang diajukan peneliti terhadap rumusan masalah penelitian disebut...",
                  options: const [],
                  correctAnswerIndex: 0,
                  type: "isian_singkat",
                  correctAnswerText: "hipotesis",
                  topicTag: "Metode Ilmiah",
                ),
              ],
              isPublished: true,
            );
            await MockDb.save('assessments', mockQuizUtama.assessmentId, mockQuizUtama.toJson());
            
            print("Self-Healing: Berhasil men-generate ulang summary & kuis untuk ${material.materialId}");
          });
        }
        
        return material;
      });
    }

    return _firestore!
        .collection('materials')
        .doc(materialId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) {
            throw Exception('Materi tidak ditemukan.');
          }
          return MaterialModel.fromJson(doc.data()!);
        });
  }

  @override
  Stream<double> uploadMaterialFile({
    required String materialId,
    required String classId,
    required String fileName,
    required List<int> fileBytes,
  }) {
    if (isMockMode) {
      // Simulasikan progress bar unggahan file
      final controller = StreamController<double>();
      int counter = 0;
      Timer.periodic(const Duration(milliseconds: 200), (timer) {
        counter++;
        final progress = counter * 0.2;
        if (progress >= 1.0) {
          if (!controller.isClosed) {
            controller.add(1.0);
            controller.close();
          }
          timer.cancel();
        } else {
          if (!controller.isClosed) {
            controller.add(progress);
          }
        }
      });
      return controller.stream;
    }

    final ref = _storage!.ref().child('materials/$classId/$materialId/$fileName');
    final uploadTask = ref.putData(Uint8List.fromList(fileBytes));

    return uploadTask.snapshotEvents.map((snapshot) {
      if (snapshot.totalBytes == 0) return 0.0;
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }

  @override
  Future<void> saveMaterialMetadata(MaterialModel material, {List<int>? fileBytes}) async {
    if (isMockMode) {
      if (fileBytes != null) {
        _mockFileBytes[material.materialId] = fileBytes;
      }
      // Simpan materi kosong (summary = null) terlebih dahulu
      await MockDb.save('materials', material.materialId, material.toJson());
      
      // Jalankan proses pengiriman ke FastAPI Backend secara asinkron agar tidak memblokir UI
      Future.microtask(() async {
        try {
          if (fileBytes != null && fileBytes.isNotEmpty) {
            print("Mock Repository: Menghubungi FastAPI Backend lokal untuk memproses ${material.title}...");
            final uri = Uri.parse("http://127.0.0.1:8000/api/process-material-file");
            final request = http.MultipartRequest("POST", uri);
            
            String ext = material.fileType.toLowerCase();
            String mime = "application/pdf";
            if (ext == "docx") mime = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
            if (ext == "pptx") mime = "application/vnd.openxmlformats-officedocument.presentationml.presentation";
            
            final multipartFile = http.MultipartFile.fromBytes(
              "file",
              fileBytes,
              filename: "document.$ext",
            );
            request.files.add(multipartFile);
            
            final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
            final response = await http.Response.fromStream(streamedResponse);
            
            if (response.statusCode == 200) {
              final result = json.decode(response.body) as Map<String, dynamic>;
              final summaryText = result['summary'] as String? ?? '';
              
              // 1. Simpan materi ter-update dengan ringkasan asli hasil Gemini
              final updatedMaterial = material.copyWith(summary: summaryText);
              await MockDb.save('materials', material.materialId, updatedMaterial.toJson());
              
              // 2. Simpan Asesmen Quick Check asli hasil Gemini
              final rawQc = result['quick_check'] as List<dynamic>? ?? [];
              final mockQuickCheck = AssessmentModel(
                assessmentId: "qc_${material.materialId}",
                materialId: material.materialId,
                classId: material.classId,
                type: "quick_check",
                questions: rawQc.map((q) {
                  final optionsList = (q['options'] as List<dynamic>?)?.map((o) => o.toString()).toList() ?? [];
                  return QuestionModel(
                    questionId: "q_${rawQc.indexOf(q)}",
                    questionText: q['questionText'] as String? ?? '',
                    options: optionsList,
                    correctAnswerIndex: q['correctAnswerIndex'] as int? ?? 0,
                  );
                }).toList(),
                isPublished: true,
              );
              await MockDb.save('assessments', mockQuickCheck.assessmentId, mockQuickCheck.toJson());

              // 3. Simpan Kuis Utama asli hasil Gemini
              final rawQuiz = result['quiz_utama'] as List<dynamic>? ?? [];
              final mockQuizUtama = AssessmentModel(
                assessmentId: "quiz_${material.materialId}",
                materialId: material.materialId,
                classId: material.classId,
                type: "quiz_utama",
                questions: rawQuiz.map((q) {
                  final optionsList = (q['options'] as List<dynamic>?)?.map((o) => o.toString()).toList() ?? [];
                  return QuestionModel(
                    questionId: "quiz_q_${rawQuiz.indexOf(q)}",
                    questionText: q['questionText'] as String? ?? '',
                    options: optionsList,
                    correctAnswerIndex: q['correctAnswerIndex'] as int? ?? 0,
                  );
                }).toList(),
                isPublished: true,
              );
              await MockDb.save('assessments', mockQuizUtama.assessmentId, mockQuizUtama.toJson());
              
              print("Mock Repository: Berhasil memproses dokumen '${material.title}' via real Gemini API di backend!");
              return;
            }
          }
        } catch (e) {
          print("Warning: Gagal memproses via FastAPI Backend lokal (menghubungi local server error: $e). Menjalankan mock fallback...");
        }
        
        // ==========================================
        // FALLBACK: Jalankan simulasi timer 4 detik jika gagal memanggil API lokal
        // ==========================================
        print("Mock Repository: Menjalankan fallback simulasi AI untuk ${material.title}...");
        await Future.delayed(const Duration(seconds: 4));
        final updatedMaterial = material.copyWith(
          summary: "Dokumen pembelajaran '${material.title}' ini menjelaskan konsep-konsep inti yang mencakup definisi teoretis, struktur formula utama, langkah-langkah penyelesaian matematis, serta studi kasus kontekstual dalam kehidupan sehari-hari secara mendalam dan terarah.",
        );
        await MockDb.save('materials', material.materialId, updatedMaterial.toJson());
        
        final mockQuickCheck = AssessmentModel(
          assessmentId: "qc_${material.materialId}",
          materialId: material.materialId,
          classId: material.classId,
          type: "quick_check",
          questions: [
            QuestionModel(
              questionId: "q_qc_1",
              questionText: "Hingga kini penyakit AIDS belum ada obatnya. Penelitian dilakukan oleh para ahli untuk mengetahui aktivitas Virus HIV pada tingkat organisasi kehidupan yaitu...",
              options: const ["A. Molekul", "B. Sel", "C. Jaringan", "D. Organ", "E. Sistem organ"],
              correctAnswerIndex: 1,
              type: "pilihan_ganda",
              topicTag: "Organisasi Kehidupan",
            ),
            QuestionModel(
              questionId: "q_qc_2",
              questionText: "Pembuatan film terkenal Jurassic Park menceritakan kehidupan hewan purba. Cabang ilmu biologi yang paling berperan dalam memodelkan hewan purba tersebut adalah...",
              options: const ["A. Evolusi", "B. Botani", "C. Zoologi", "D. Palaeontologi", "E. Anatomi"],
              correctAnswerIndex: 3,
              type: "pilihan_ganda",
              topicTag: "Cabang Biologi",
            ),
            QuestionModel(
              questionId: "q_qc_3",
              questionText: "Seseorang yang akan menjalani transplantasi organ hati perlu memahami struktur fungsi hati. Studi tersebut dipelajari pada tingkat organisasi...",
              options: const ["A. Sel", "B. Jaringan", "C. Organ", "D. Sistem organ", "E. Individu"],
              correctAnswerIndex: 2,
              type: "pilihan_ganda",
              topicTag: "Organisasi Kehidupan",
            ),
          ],
          isPublished: true,
        );
        await MockDb.save('assessments', mockQuickCheck.assessmentId, mockQuickCheck.toJson());

        final mockQuizUtama = AssessmentModel(
          assessmentId: "quiz_${material.materialId}",
          materialId: material.materialId,
          classId: material.classId,
          type: "quiz_utama",
          questions: [
            QuestionModel(
              questionId: "q_qu_1",
              questionText: "Berikut merupakan salah satu manfaat penerapan biologi di bidang peternakan secara modern adalah...",
              options: const [
                "A. Memperbanyak dengan teknik kultur jaringan",
                "B. Membuat antibodi monoklonal",
                "C. Membuat vaksin pencegah penyakit virus SARS",
                "D. Terapi gen transgenik menghasilkan susu sapi lebih berkualitas",
                "E. Menghasilkan insulin buatan"
              ],
              correctAnswerIndex: 3,
              type: "pilihan_ganda",
              topicTag: "Manfaat Biologi",
            ),
            QuestionModel(
              questionId: "q_qu_2",
              questionText: "Sekelompok peneliti melakukan pengamatan terhadap perilaku sekumpulan harimau Sumatera (Panthera tigris sumatrae). Tingkat organisasi kehidupan yang diamati adalah...",
              options: const ["A. Ekosistem", "B. Komunitas", "C. Populasi", "D. Individu", "E. Bioma"],
              correctAnswerIndex: 2,
              type: "pilihan_ganda",
              topicTag: "Organisasi Kehidupan",
            ),
            QuestionModel(
              questionId: "q_qu_3",
              questionText: "Seorang peneliti mengamati lingkungan X dan menemukan bahwa banyak bayi terlahir cacat akibat kekurangan gizi serta polusi logam berat. Bidang studi biologi yang mempelajari cacat perkembangan embrio ini adalah...",
              options: const ["A. Parasitologi", "B. Ginekologi", "C. Teratologi", "D. Genetika", "E. Fisiologi"],
              correctAnswerIndex: 2,
              type: "pilihan_ganda",
              topicTag: "Cabang Biologi",
            ),
            QuestionModel(
              questionId: "q_qu_4",
              questionText: "Dalam suatu langkah metode ilmiah, eksperimen atau percobaan dilakukan secara terkontrol untuk menguji...",
              options: const ["A. Pengumpulan data", "B. Rumusan masalah", "C. Latar belakang", "D. Kesimpulan", "E. Hipotesis"],
              correctAnswerIndex: 4,
              type: "pilihan_ganda",
              topicTag: "Metode Ilmiah",
            ),
            QuestionModel(
              questionId: "q_qu_5",
              questionText: "Perilaku yang benar, aman, dan menjaga keselamatan kerja saat berada di dalam laboratorium biologi adalah...",
              options: const ["A. Membawa bekal makanan", "B. Mengenakan pakaian ketat", "C. Bersikap serius dan tekun", "D. Bersikap gembira dan bercanda", "E. Menggunakan seragam sekolah ketat"],
              correctAnswerIndex: 2,
              type: "pilihan_ganda",
              topicTag: "Keselamatan Kerja",
            ),
            QuestionModel(
              questionId: "q_qu_6",
              questionText: "Jika Anda memasuki laboratorium dan melihat simbol botol pecah mengeluarkan cairan korosif, berarti zat tersebut bersifat...",
              options: const ["A. Korosif", "B. Beracun", "C. Radioaktif", "D. Mudah meledak", "E. Mudah terbakar"],
              correctAnswerIndex: 0,
              type: "pilihan_ganda",
              topicTag: "Keselamatan Kerja",
            ),
            // Soal Majemuk Kompleks
            QuestionModel(
              questionId: "q_qu_7",
              questionText: "Tentukan Benar (B) atau Salah (S) untuk pernyataan keselamatan kerja berikut:\n1. Membuang sisa limbah asam pekat langsung ke wastafel diperbolehkan.\n2. Selalu gunakan jas lab kancing lengkap saat berada di laboratorium.",
              options: const [],
              correctAnswerIndex: 0,
              type: "majemuk_kompleks",
              correctAnswers: const [0, 1],
              topicTag: "Keselamatan Kerja",
            ),
            QuestionModel(
              questionId: "q_qu_8",
              questionText: "Tentukan Benar (B) atau Salah (S) untuk pernyataan tingkat organisasi kehidupan berikut:\n1. Kumpulan sel sejenis yang memiliki bentuk dan fungsi sama disebut jaringan.\n2. Tingkatan organisasi kehidupan tertinggi di biosfer adalah individu tunggal.",
              options: const [],
              correctAnswerIndex: 0,
              type: "majemuk_kompleks",
              correctAnswers: const [1, 0],
              topicTag: "Organisasi Kehidupan",
            ),
            // Soal Isian Singkat
            QuestionModel(
              questionId: "q_qu_9",
              questionText: "Langkah pertama dalam metode ilmiah setelah mengamati fenomena alam secara seksama adalah merumuskan...",
              options: const [],
              correctAnswerIndex: 0,
              type: "isian_singkat",
              correctAnswerText: "masalah",
              topicTag: "Metode Ilmiah",
            ),
            QuestionModel(
              questionId: "q_qu_10",
              questionText: "Dugaan awal atau jawaban sementara yang diajukan peneliti terhadap rumusan masalah penelitian disebut...",
              options: const [],
              correctAnswerIndex: 0,
              type: "isian_singkat",
              correctAnswerText: "hipotesis",
              topicTag: "Metode Ilmiah",
            ),
          ],
          isPublished: true,
        );
        await MockDb.save('assessments', mockQuizUtama.assessmentId, mockQuizUtama.toJson());
        print("Mock Repository: Berhasil menyelesaikan mock fallback untuk ${material.materialId}");
      });
      return;
    }
    await _firestore!
        .collection('materials')
        .doc(material.materialId)
        .set(material.toFirestore());
  }

  @override
  Future<String> getDownloadUrl(String path) async {
    if (isMockMode) {
      // URL contoh PDF agar penampil PDF (syncfusion_flutter_pdfviewer) tidak crash saat uji coba lokal
      return "https://pdfobject.com/pdf/sample.pdf";
    }
    return await _storage!.ref().child(path).getDownloadURL();
  }
}
