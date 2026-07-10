import '../../data/models/question_bank_model.dart';

abstract class QuestionBankRepository {
  /// Mengambil bank soal berdasarkan materialId.
  Future<QuestionBankModel?> fetchQuestionBank(String materialId);

  /// Memicu pembuatan bank soal AI via backend Python.
  /// Mengembalikan true jika berhasil, throw exception jika gagal.
  Future<bool> triggerBankGeneration({
    required String materialId,
    required String classId,
    required String fileUrl,
    required String fileType,
  });
}
