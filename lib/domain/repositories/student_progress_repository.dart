import '../../data/models/student_progress_model.dart';
import '../../data/models/quick_check_session_model.dart';

abstract class StudentProgressRepository {
  /// Mengambil progress siswa untuk materi tertentu.
  Future<StudentProgressModel?> getProgress(String studentId, String materialId);

  /// Menyimpan/update progress siswa.
  Future<void> updateProgress(StudentProgressModel progress);

  /// Menyimpan sesi Quick Check baru.
  Future<void> saveQuickCheckSession(QuickCheckSessionModel session);

  /// Mengupdate sesi Quick Check yang sudah ada (setelah submit).
  Future<void> updateQuickCheckSession(QuickCheckSessionModel session);
}
