import 'package:flutter_bloc/flutter_bloc.dart';

import 'learning_health_event.dart';
import 'learning_health_state.dart';

class LearningHealthBloc extends Bloc<LearningHealthEvent, LearningHealthState> {
  LearningHealthBloc() : super(const LearningHealthInitial()) {
    on<LoadLearningHealth>(_onLoadLearningHealth);
  }

  Future<void> _onLoadLearningHealth(
    LoadLearningHealth event,
    Emitter<LearningHealthState> emit,
  ) async {
    emit(const LearningHealthLoading());

    try {
      // ── DUMMY DATA untuk demo F-18 ──
      // Pada production, data ini dihitung secara dinamis dari aktivitas belajar di Firestore:
      // - Konsistensi: query data aktivitas dalam 7 hari terakhir, hitung jumlah hari unik.
      // - Fokus: rata-rata focusScore dari koleksi activities.
      // - Durasi: total readDurationSec diubah ke menit vs target (misal target 120 menit).
      // - Penyelesaian: persentase isCompleted == true dari activities.

      final studyDays = 5; // 5 hari dari 7 hari terakhir
      final avgFocus = 82.7; // 82.7%
      final totalDuration = 96; // 96 menit
      final targetDuration = 120; // target 120 menit seminggu
      final completionRate = 88.0; // 88% materi diselesaikan tepat waktu

      // Tentukan status untuk setiap parameter
      final consistencyStatus = _determineStatus(studyDays / 7 * 100);
      final focusStatus = _determineStatus(avgFocus);
      final durationStatus = _determineStatus(totalDuration / targetDuration * 100);
      final completionStatus = _determineStatus(completionRate);

      final indicators = [
        HealthIndicator(
          label: 'Konsistensi Belajar',
          value: '$studyDays Hari / Minggu',
          progress: studyDays / 7,
          status: consistencyStatus,
          description: _getConsistencyDescription(consistencyStatus, studyDays),
        ),
        HealthIndicator(
          label: 'Tingkat Fokus',
          value: '${avgFocus.toStringAsFixed(1)}%',
          progress: avgFocus / 100,
          status: focusStatus,
          description: _getFocusDescription(focusStatus, avgFocus),
        ),
        HealthIndicator(
          label: 'Aktivitas Pembelajaran',
          value: '$totalDuration / $targetDuration Menit',
          progress: (totalDuration / targetDuration).clamp(0.0, 1.0),
          status: durationStatus,
          description: _getDurationDescription(durationStatus, totalDuration, targetDuration),
        ),
        HealthIndicator(
          label: 'Frekuensi Penyelesaian',
          value: '${completionRate.toStringAsFixed(0)}%',
          progress: completionRate / 100,
          status: completionStatus,
          description: _getCompletionDescription(completionStatus, completionRate),
        ),
      ];

      // Tentukan kondisi kesehatan belajar keseluruhan
      final averageMetrics = ( (studyDays / 7 * 100) + avgFocus + (totalDuration / targetDuration * 100).clamp(0, 100) + completionRate ) / 4;
      final overallHealth = _determineStatus(averageMetrics);

      emit(LearningHealthLoaded(
        childName: 'Ahmad Fauzi',
        studyDaysThisWeek: studyDays,
        averageFocusScore: avgFocus,
        totalStudyDurationMinutes: totalDuration,
        targetStudyDurationMinutes: targetDuration,
        completionRate: completionRate,
        overallHealth: overallHealth,
        indicators: indicators,
      ));
    } catch (e) {
      emit(LearningHealthError('Gagal memuat kesehatan belajar: $e'));
    }
  }

  HealthStatus _determineStatus(double percentage) {
    if (percentage >= 80) return HealthStatus.healthy;
    if (percentage >= 60) return HealthStatus.moderate;
    return HealthStatus.attention;
  }

  String _getConsistencyDescription(HealthStatus status, int days) {
    switch (status) {
      case HealthStatus.healthy:
        return 'Sangat baik! Anak Anda belajar secara teratur hampir setiap hari minggu ini.';
      case HealthStatus.moderate:
        return 'Cukup konsisten. Anak belajar $days hari. Tingkatkan lagi agar belajar lebih terjadwal.';
      default:
        return 'Perlu perhatian. Anak hanya belajar $days hari minggu ini. Buat jadwal harian untuk membantu anak.';
    }
  }

  String _getFocusDescription(HealthStatus status, double score) {
    switch (status) {
      case HealthStatus.healthy:
        return 'Hebat! Konsentrasi anak sangat tinggi saat membaca modul pembelajaran.';
      case HealthStatus.moderate:
        return 'Fokus anak cukup stabil, namun kadang terdistraksi saat membaca materi yang panjang.';
      default:
        return 'Anak sering terdistraksi atau meninggalkan halaman membaca sebelum selesai. Coba dampingi saat membaca.';
    }
  }

  String _getDurationDescription(HealthStatus status, int duration, int target) {
    if (duration >= target) {
      return 'Luar biasa! Anak telah melampaui target durasi belajar mingguan.';
    }
    final gap = target - duration;
    switch (status) {
      case HealthStatus.healthy:
        return 'Hampir mencapai target! Hanya kurang $gap menit untuk mencapai target belajar minggu ini.';
      case HealthStatus.moderate:
        return 'Cukup aktif. Anak belajar selama $duration menit. Butuh sekitar $gap menit lagi.';
      default:
        return 'Durasi belajar anak masih sangat kurang dari target ($duration/$target menit).';
    }
  }

  String _getCompletionDescription(HealthStatus status, double rate) {
    switch (status) {
      case HealthStatus.healthy:
        return 'Sangat patuh! Hampir seluruh materi yang dibuka diselesaikan tepat waktu.';
      case HealthStatus.moderate:
        return 'Cukup baik. Sebagian besar materi selesai dibaca, tapi ada beberapa yang terlewati.';
      default:
        return 'Anak sering menutup materi sebelum selesai membacanya secara tuntas.';
    }
  }
}
