import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/talent/talent_bloc.dart';
import '../../bloc/talent/talent_event.dart';
import '../../bloc/talent/talent_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/shared_ui_kit.dart';
import '../../../domain/repositories/class_repository.dart';

class TalentRecommendationPage extends StatefulWidget {
  final String? classId;

  const TalentRecommendationPage({super.key, this.classId});

  @override
  State<TalentRecommendationPage> createState() => _TalentRecommendationPageState();
}

class _TalentRecommendationPageState extends State<TalentRecommendationPage> {
  List<String>? _classStudentUids;
  bool _isLoadingClass = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    String teacherId = 'mock_teacher_1';
    if (authState is Authenticated) {
      teacherId = authState.user.uid;
    }
    context.read<TalentBloc>().add(FetchTalentRecommendations(teacherId));
    _loadClassStudents();
  }

  Future<void> _loadClassStudents() async {
    if (widget.classId != null) {
      setState(() {
        _isLoadingClass = true;
      });
      try {
        final classDetail = await context.read<ClassRepository>().streamClassDetail(widget.classId!).first;
        setState(() {
          _classStudentUids = classDetail.studentUids;
          _isLoadingClass = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingClass = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // HSL Golden Amber Color Palette
    final amberColor = const HSLColor.fromAHSL(1.0, 40, 0.95, 0.50).toColor();
    final amberLight = const HSLColor.fromAHSL(1.0, 40, 0.95, 0.94).toColor();
    final amberText = const HSLColor.fromAHSL(1.0, 40, 0.90, 0.25).toColor();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const SharedAppBar(
        title: 'Rekomendasi Bakat Siswa',
      ),
      body: BlocBuilder<TalentBloc, TalentState>(
        builder: (context, state) {
          if (state is TalentLoading || _isLoadingClass) {
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
            var recs = state.recommendations;

            // Filter recommendations by class student UIDs if classId is specified
            if (widget.classId != null && _classStudentUids != null) {
              recs = recs.where((rec) => _classStudentUids!.contains(rec.studentId)).toList();
            }

            if (recs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Tidak ada rekomendasi bakat siswa untuk kelas ini saat ini.'),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Info
                  SharedCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 16,
                    color: AppColors.primaryLight.withValues(alpha: 0.05),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.15), width: 1.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.stars_rounded, color: AppColors.primaryLight, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analisis Bakat AI Terdeteksi',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AI SI-FOKUS menganalisis tingkat konsistensi kuis, fokus membaca modul (scroll velocity), keaktifan, dan durasi belajar untuk merekomendasikan siswa pada ajang kompetisi nasional.',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppColors.textSecondaryLight,
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

                      return SharedCard(
                        margin: const EdgeInsets.only(bottom: 20),
                        borderRadius: 24,
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.18),
                          width: 1.5,
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
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Badge Bidang Rekomendasi
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(30),
                                            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
                                          ),
                                          child: Text(
                                            'Rekomendasi: ${rec.recommendedField.toUpperCase()}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryLight,
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
                                            valueColor: AppColors.primaryLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$scorePercent% Cocok',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppColors.primaryLight,
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
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                rec.reasoning,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.textPrimaryLight.withValues(alpha: 0.85),
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
