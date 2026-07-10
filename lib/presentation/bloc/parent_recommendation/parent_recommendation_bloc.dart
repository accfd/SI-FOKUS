import 'package:flutter_bloc/flutter_bloc.dart';

import 'parent_recommendation_event.dart';
import 'parent_recommendation_state.dart';

class ParentRecommendationBloc
    extends Bloc<ParentRecommendationEvent, ParentRecommendationState> {
  ParentRecommendationBloc() : super(const ParentRecommendationInitial()) {
    on<LoadParentRecommendations>(_onLoadParentRecommendations);
  }

  Future<void> _onLoadParentRecommendations(
    LoadParentRecommendations event,
    Emitter<ParentRecommendationState> emit,
  ) async {
    emit(const ParentRecommendationLoading());

    try {
      // ── DUMMY DATA untuk demo F-19 ──
      // Pada production, data ini ditarik dari Cloud Firestore:
      // Koleksi: /student_competencies (strengths, weaknesses, recommendations)
      // Gemini API di backend mengidentifikasi kelemahan anak dan menghasilkan narasi rekomendasi humanis khusus orang tua.

      final dummyRecommendations = [
        const RecommendationModel(
          title: 'Pendampingan Visual Sistem Pencernaan',
          category: 'Biologi',
          recommendationText:
              'Anak Anda sedang mempelajari Sistem Pencernaan dan sempat mengalami penurunan fokus saat membaca modul teks yang panjang. Ia akan belajar jauh lebih baik jika didampingi dengan media visual.',
          actionStep:
              'Coba tonton video animasi sistem pencernaan singkat bersama anak selama 10-15 menit di YouTube, lalu tanyakan secara santai organ apa saja yang dilewati makanan. Ini membantu retensi pemahaman visualnya.',
          iconType: 'biology',
        ),
        const RecommendationModel(
          title: 'Metode Membaca "Stop and Reflect"',
          category: 'Fokus Membaca',
          recommendationText:
              'Berdasarkan data AI Focus Tracker, anak Anda memiliki kecenderungan melakukan scroll sangat cepat (abnormal scroll) saat membaca halaman PDF modul setelah 5 menit pertama.',
          actionStep:
              'Dampingi anak membaca dan ingatkan dia untuk berhenti sejenak setiap selesai membaca satu sub-bab. Tanyakan padanya: "Apa poin penting dari sub-bab ini?" sebelum melanjutkan membaca ke halaman berikutnya.',
          iconType: 'focus',
        ),
        const RecommendationModel(
          title: 'Latihan Aljabar Menggunakan Benda Rumah',
          category: 'Matematika',
          recommendationText:
              'Hasil kuis anak pada topik Aljabar menunjukkan kesulitan dalam memahami konsep variabel (x dan y) jika disajikan hanya berupa simbol abstrak.',
          actionStep:
              'Gunakan contoh nyata di meja makan. Misalnya: "Jika Ibu punya 3 apel dan x jeruk, lalu total buahnya 8, berapa jeruk yang ada?". Ini membantu menjembatani pemahaman abstrak ke konkrit.',
          iconType: 'math',
        ),
        const RecommendationModel(
          title: 'Apresiasi Konsistensi Belajar',
          category: 'Kebiasaan Belajar',
          recommendationText:
              'Meskipun skor kuis anak berfluktuasi, tingkat kerajinan belajarnya sangat baik (5 hari aktif belajar minggu ini). Dorongan motivasi akan meningkatkan rasa percaya dirinya.',
          actionStep:
              'Berikan pujian yang berfokus pada usahanya, bukan nilainya. Katakan: "Ibu bangga melihat kamu tekun membaca modul setiap sore." Hal ini akan memperkuat kebiasaan belajarnya.',
          iconType: 'habit',
        ),
      ];

      emit(ParentRecommendationLoaded(
        childName: 'Ahmad Fauzi',
        recommendations: dummyRecommendations,
      ));
    } catch (e) {
      emit(ParentRecommendationError('Gagal memuat rekomendasi: $e'));
    }
  }
}
