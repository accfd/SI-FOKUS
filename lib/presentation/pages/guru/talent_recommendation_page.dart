import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/talent/talent_bloc.dart';
import '../../bloc/talent/talent_event.dart';
import '../../bloc/talent/talent_state.dart';

class TalentRecommendationPage extends StatefulWidget {
  const TalentRecommendationPage({super.key});

  @override
  State<TalentRecommendationPage> createState() => _TalentRecommendationPageState();
}

class _TalentRecommendationPageState extends State<TalentRecommendationPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    String teacherId = 'mock_teacher_1';
    if (authState is Authenticated) {
      teacherId = authState.user.uid;
    }
    context.read<TalentBloc>().add(FetchTalentRecommendations(teacherId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // HSL Golden Amber Color Palette
    final amberColor = const HSLColor.fromAHSL(1.0, 40, 0.95, 0.50).toColor();
    final amberLight = const HSLColor.fromAHSL(1.0, 40, 0.95, 0.94).toColor();
    final amberText = const HSLColor.fromAHSL(1.0, 40, 0.90, 0.25).toColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekomendasi Bakat AI'),
      ),
      body: BlocBuilder<TalentBloc, TalentState>(
        builder: (context, state) {
          if (state is TalentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TalentError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal memuat rekomendasi bakat',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(state.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          if (state is TalentLoaded) {
            final recs = state.recommendations;

            if (recs.isEmpty) {
              return const Center(
                child: Text('Tidak ada siswa yang direkomendasikan saat ini.'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: amberLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: amberColor.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.stars_rounded, color: amberColor, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analisis Bakat AI Terdeteksi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: amberText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AI SI-FOKUS menganalisis tingkat konsistensi kuis, fokus membaca modul (scroll velocity), keaktifan, dan durasi belajar untuk merekomendasikan siswa pada ajang kompetisi nasional.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: amberText.withValues(alpha: 0.85),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recommendations Cards List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recs.length,
                    itemBuilder: (context, index) {
                      final rec = recs[index];
                      final scorePercent = (rec.confidenceScore * 100).toInt();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rec.studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Badge Bidang Rekomendasi
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: amberLight,
                                            borderRadius: BorderRadius.circular(30),
                                            border: Border.all(color: amberColor.withValues(alpha: 0.2)),
                                          ),
                                          child: Text(
                                            'Rekomendasi: ${rec.recommendedField.toUpperCase()}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: amberText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Semi Circular Gauge Widget
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        height: 50,
                                        child: CustomPaint(
                                          painter: SemiCircularGaugePainter(
                                            score: rec.confidenceScore,
                                            trackColor: Colors.grey.shade200,
                                            valueColor: amberColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$scorePercent% Cocok',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: amberText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'Analisis AI & Justifikasi:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                rec.reasoning,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Belum ada analisis rekomendasi bakat.'));
        },
      ),
    );
  }
}

// Custom Painter untuk Menggambar Grafik Semi-Circular Gauge Melengkung
class SemiCircularGaugePainter extends CustomPainter {
  final double score;
  final Color trackColor;
  final Color valueColor;

  SemiCircularGaugePainter({
    required this.score,
    required this.trackColor,
    required this.valueColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2, size.height);
    final strokeWidth = radius * 0.22;

    // 1. Gambar jalur lingkar abu-abu (track)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      pi,
      pi,
      false,
      trackPaint,
    );

    // 2. Gambar jalur lengkung nilai (value)
    final valuePaint = Paint()
      ..color = valueColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      pi,
      pi * score,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant SemiCircularGaugePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.valueColor != valueColor;
  }
}
