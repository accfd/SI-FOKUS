import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/learning_health/learning_health_bloc.dart';
import '../../bloc/learning_health/learning_health_event.dart';
import '../../bloc/learning_health/learning_health_state.dart';

class LearningHealthPage extends StatelessWidget {
  const LearningHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LearningHealthBloc()
        ..add(const LoadLearningHealth(studentUid: 'dummy_student')),
      child: const _LearningHealthView(),
    );
  }
}

class _LearningHealthView extends StatelessWidget {
  const _LearningHealthView();

  // ── Palette Warna Kebugaran Belajar Menenangkan ──
  static const Color _primary = Color(0xFF2E7D6F);
  static const Color _primaryDark = Color(0xFF1B5E50);
  static const Color _surface = Color(0xFFF5FAF8);
  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF1A3C34);
  static const Color _textSecondary = Color(0xFF5F7B74);

  static const Color _greenHealth = Color(0xFF43A047);
  static const Color _yellowHealth = Color(0xFFFFB300);
  static const Color _redHealth = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Text(
          'Kesehatan Belajar',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<LearningHealthBloc, LearningHealthState>(
        builder: (context, state) {
          if (state is LearningHealthLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }
          if (state is LearningHealthError) {
            return Center(
              child: Text(
                state.message,
                style: GoogleFonts.outfit(color: _textSecondary),
              ),
            );
          }
          if (state is LearningHealthLoaded) {
            return _buildLoadedView(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, LearningHealthLoaded state) {
    final statusColor = _getStatusColor(state.overallHealth);
    final statusText = _getStatusText(state.overallHealth);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. RINGKASAN GAUGE KESEHATAN UTAMA ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Kondisi Aktivitas Belajar Anak',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  height: 120,
                  child: CustomPaint(
                    painter: _GaugePainter(
                      score: state.averageFocusScore,
                      color: statusColor,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${state.averageFocusScore.toStringAsFixed(1)}%',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                          Text(
                            'Fokus Rata-Rata',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Kategori: $statusText',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── 2. INDIKATOR PARAMETER BELAJAR (FITNESS STYLE) ──
          Text(
            'Indikator Kesehatan Belajar',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.indicators.length,
            itemBuilder: (context, index) {
              final indicator = state.indicators[index];
              return _buildFitnessCard(indicator);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ═══════════════════════════════
  //  CARD INDIKATOR STYLE KEBUGARAN
  // ═══════════════════════════════
  Widget _buildFitnessCard(HealthIndicator indicator) {
    final statusColor = _getStatusColor(indicator.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                indicator.label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              Text(
                indicator.value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: indicator.progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  indicator.description,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: _textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return _greenHealth;
      case HealthStatus.moderate:
        return _yellowHealth;
      case HealthStatus.attention:
        return _redHealth;
    }
  }

  String _getStatusText(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return 'Sangat Sehat & Fokus';
      case HealthStatus.moderate:
        return 'Cukup Stabil';
      case HealthStatus.attention:
        return 'Perlu Perhatian';
    }
  }
}

// ── CUSTOM GAUGE PAINTER UNTUK SEMI CIRCLE METER ──
class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;

  const _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    // Track arc
    final trackPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      trackPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
