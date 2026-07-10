import 'package:flutter_bloc/flutter_bloc.dart';

import 'talent_report_event.dart';
import 'talent_report_state.dart';

class TalentReportBloc extends Bloc<TalentReportEvent, TalentReportState> {
  TalentReportBloc() : super(const TalentReportInitial()) {
    on<LoadTalentReport>(_onLoadTalentReport);
  }

  Future<void> _onLoadTalentReport(
    LoadTalentReport event,
    Emitter<TalentReportState> emit,
  ) async {
    emit(const TalentReportLoading());

    try {
      // ── DUMMY DATA untuk demo F-20 ──
      // Pada production, data ini ditarik dari Firestore collection:
      // /talent_recommendations/{id}
      // AI Backend memproses kecerdasan spasial/linguistik/matematis anak dari data belajar.

      final dummyRecommendation = const TalentRecommendationModel(
        studentId: 'dummy_student',
        recommendedField: 'Sains & Biologi',
        confidenceScore: 92.5,
        reasoning:
            'Ahmad Fauzi menunjukkan ketertarikan serta bakat alami yang sangat menonjol di bidang Sains (khususnya Biologi). Data AI Focus Tracker mendeteksi bahwa saat membaca modul sains, Ahmad memiliki durasi membaca terlama (rata-rata 12 menit per sesi) dengan stabilitas fokus mencapai 85%. Lebih lanjut, Ahmad selalu berhasil melampaui ambang batas nilai Quick Check sains pada percobaan pertama dan berhasil menyelesaikan Kuis Utama Biologi dengan hasil di atas rata-rata kelas. Ahmad menyukai pemahaman konsep berbasis sebab-akibat alamiah dan eksplorasi visual.',
        recommendedCompetitions: [
          'Olimpiade Sains Nasional (OSN) SMP Bidang IPA',
          'Indonesia Science Competition (ISC) Bidang Biologi',
          'KiHajar STEM (Kemendikbudristek) Kategori Sains',
        ],
        supportSteps: [
          'Sediakan ensiklopedia sains atau buku biologi populer bergambar di rumah untuk memperluas wawasannya secara non-formal.',
          'Fasilitasi eksperimen sains sederhana di rumah, seperti mengamati pertumbuhan tanaman kacang hijau atau siklus air dalam wadah tertutup.',
          'Ajak anak berdiskusi santai tentang fenomena alam di sekitar rumah (misalnya: mengapa daun berwarna hijau, atau bagaimana semut bekerja sama).',
          'Dukung dan daftarkan anak untuk mengikuti lomba sains tingkat sekolah atau komunitas untuk melatih rasa percaya dirinya.',
        ],
      );

      emit(TalentReportLoaded(
        childName: 'Ahmad Fauzi',
        talentRecommendation: dummyRecommendation,
      ));
    } catch (e) {
      emit(TalentReportError('Gagal memuat laporan bakat: $e'));
    }
  }
}
