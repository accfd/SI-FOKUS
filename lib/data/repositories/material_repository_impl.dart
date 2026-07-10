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
            
            // Generate Quick Check
            final mockQuickCheck = AssessmentModel(
              assessmentId: "qc_${material.materialId}",
              materialId: material.materialId,
              classId: material.classId,
              type: "quick_check",
              questions: [
                QuestionModel(
                  questionId: "q1",
                  questionText: "Berdasarkan materi '${material.title}', apa tujuan utama dari topik pembelajaran ini?",
                  options: [
                    "Menguji pemahaman konsep fundamental secara cepat",
                    "Mengerjakan soal ujian akhir semester",
                    "Membuat rangkuman dokumen fisik",
                    "Menghafal seluruh materi tanpa memahaminya"
                  ],
                  correctAnswerIndex: 0,
                ),
              ],
              isPublished: true,
            );
            await MockDb.save('assessments', mockQuickCheck.assessmentId, mockQuickCheck.toJson());

            // Generate Kuis Utama
            final mockQuizUtama = AssessmentModel(
              assessmentId: "quiz_${material.materialId}",
              materialId: material.materialId,
              classId: material.classId,
              type: "quiz_utama",
              questions: List.generate(10, (index) {
                return QuestionModel(
                  questionId: "quiz_q_${index + 1}",
                  questionText: "Soal Kuis Utama #${index + 1}: Manakah pilihan yang paling merepresentasikan pemahaman mendalam tentang '${material.title}'?",
                  options: [
                    "Jawaban opsi A (Konsep terstruktur)",
                    "Jawaban opsi B (Penjelasan teoritis dasar)",
                    "Jawaban opsi C (Aplikasi penyelesaian masalah)",
                    "Jawaban opsi D (Metode analisis lanjutan)"
                  ],
                  correctAnswerIndex: index % 4,
                );
              }),
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
              questionId: "q1",
              questionText: "Berdasarkan materi '${material.title}', apa tujuan utama dari topik pembelajaran ini?",
              options: [
                "Menguji pemahaman konsep fundamental secara cepat",
                "Mengerjakan soal ujian akhir semester",
                "Membuat rangkuman dokumen fisik",
                "Menghafal seluruh materi tanpa memahaminya"
              ],
              correctAnswerIndex: 0,
            ),
            QuestionModel(
              questionId: "q2",
              questionText: "Manakah di bawah ini yang merupakan komponen penting yang dibahas dalam modul?",
              options: [
                "Struktur teoretis dan pemecahan kasus secara logis",
                "Metode penulisan cepat tanpa analisis",
                "Kumpulan rumus fisika tingkat lanjut",
                "Hukum Newton tentang gerak benda"
              ],
              correctAnswerIndex: 0,
            ),
            QuestionModel(
              questionId: "q3",
              questionText: "Bagaimana cara menyimpulkan hasil evaluasi dari topik '${material.title}'?",
              options: [
                "Menganalisis hasil pengerjaan kuis dan kestabilan fokus belajar",
                "Hanya melihat durasi waktu membaca tanpa memperhatikan fokus",
                "Menyalin seluruh isi materi ke buku catatan",
                "Mengganti tab browser sesering mungkin saat belajar"
              ],
              correctAnswerIndex: 0,
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
          questions: List.generate(10, (index) {
            return QuestionModel(
              questionId: "quiz_q_${index + 1}",
              questionText: "Soal Kuis Utama #${index + 1}: Manakah pilihan yang paling merepresentasikan pemahaman mendalam tentang '${material.title}'?",
              options: [
                "Jawaban opsi A (Konsep terstruktur)",
                "Jawaban opsi B (Penjelasan teoritis dasar)",
                "Jawaban opsi C (Aplikasi penyelesaian masalah)",
                "Jawaban opsi D (Metode analisis lanjutan)"
              ],
              correctAnswerIndex: index % 4,
            );
          }),
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
