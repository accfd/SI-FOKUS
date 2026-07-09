class QuizAccessValidator {
  QuizAccessValidator._();

  /// Validasi kelayakan akses siswa ke kuis.
  /// Mengembalikan pesan kesalahan [String] jika tidak memenuhi kualifikasi, atau [null] jika akses diizinkan.
  static String? validateAccess({
    required DateTime? startDate,
    required DateTime? endDate,
    required bool isPublished,
    required bool isQuickCheckPassed,
    required bool isMaterialCompleted,
  }) {
    if (!isPublished) {
      return 'Kuis belum dipublikasikan oleh guru.';
    }

    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate)) {
      return 'Kuis belum dibuka. Silakan kembali nanti.';
    }

    if (endDate != null && now.isAfter(endDate)) {
      return 'Kuis sudah ditutup.';
    }

    if (!isMaterialCompleted) {
      return 'Anda harus menyelesaikan membaca materi pendukung terlebih dahulu.';
    }

    if (!isQuickCheckPassed) {
      return 'Anda harus lulus Quick Check terlebih dahulu sebelum mengerjakan kuis utama.';
    }

    return null; // Akses diizinkan
  }
}
