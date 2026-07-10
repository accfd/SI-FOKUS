import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/talent_report/talent_report_bloc.dart';
import '../../bloc/talent_report/talent_report_event.dart';
import '../../bloc/talent_report/talent_report_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/shared_ui_kit.dart';

class TalentReportPage extends StatelessWidget {
  const TalentReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TalentReportBloc()
        ..add(const LoadTalentReport(studentUid: 'dummy_student')),
      child: const _TalentReportView(),
    );
  }
}

class _TalentReportView extends StatelessWidget {
  const _TalentReportView();

  // ── Palette Warna Menenangkan ──
  static const Color _primary = AppColors.primaryLight;
  static const Color _primaryDark = AppColors.secondaryLight;
  static const Color _surface = AppColors.backgroundLight;
  static const Color _cardBg = AppColors.cardLight;
  static const Color _textPrimary = AppColors.textPrimaryLight;
  static const Color _textSecondary = AppColors.textSecondaryLight;
  static const Color _goldAccent = AppColors.accentLight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: const SharedAppBar(
        title: 'Potensi & Bakat Anak',
      ),
      body: BlocBuilder<TalentReportBloc, TalentReportState>(
        builder: (context, state) {
          if (state is TalentReportLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }
          if (state is TalentReportError) {
            return Center(
              child: Text(
                state.message,
                style: GoogleFonts.outfit(color: _textSecondary),
              ),
            );
          }
          if (state is TalentReportLoaded) {
            return _buildLoadedView(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, TalentReportLoaded state) {
    final recommendation = state.talentRecommendation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. CARD BIDANG POTENSI UTAMA ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, _primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: _goldAccent,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bidang Potensi Unggulan',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.recommendedField,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Tingkat Keyakinan AI: ${recommendation.confidenceScore.toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── 2. NARASI HASIL DIAGNOSIS (WARM & INFORMATIVE) ──
          Text(
            'Analisis & Diagnosis AI',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SharedCard(
            color: _cardBg,
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Text(
              recommendation.reasoning,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: _textPrimary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── 3. KOMPETISI & OLIMPIADE YANG DISARANKAN ──
          Text(
            'Kompetisi / Olimpiade Terpilih',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: recommendation.recommendedCompetitions.map((comp) {
              return SharedCard(
                color: _cardBg,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _goldAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: _goldAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        comp,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // ── 4. LANGKAH DUKUNGAN ORANG TUA ──
          Text(
            'Cara Mendukung Perkembangan Anak',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SharedCard(
            color: _cardBg,
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Column(
              children: recommendation.supportSteps.map((step) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: _primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: _textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
