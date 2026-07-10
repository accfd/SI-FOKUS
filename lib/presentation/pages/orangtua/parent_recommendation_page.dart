import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/parent_recommendation/parent_recommendation_bloc.dart';
import '../../bloc/parent_recommendation/parent_recommendation_event.dart';
import '../../bloc/parent_recommendation/parent_recommendation_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/shared_ui_kit.dart';

class ParentRecommendationPage extends StatelessWidget {
  const ParentRecommendationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ParentRecommendationBloc()
        ..add(const LoadParentRecommendations(studentUid: 'dummy_student')),
      child: const _ParentRecommendationView(),
    );
  }
}

class _ParentRecommendationView extends StatelessWidget {
  const _ParentRecommendationView();

  // ── Palette Warna Menenangkan ──
  static const Color _primary = AppColors.primaryLight;
  static const Color _primaryDark = AppColors.secondaryLight;
  static const Color _surface = AppColors.backgroundLight;
  static const Color _cardBg = AppColors.cardLight;
  static const Color _textPrimary = AppColors.textPrimaryLight;
  static const Color _textSecondary = AppColors.textSecondaryLight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: const SharedAppBar(
        title: 'Rekomendasi Belajar',
      ),
      body: BlocBuilder<ParentRecommendationBloc, ParentRecommendationState>(
        builder: (context, state) {
          if (state is ParentRecommendationLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }
          if (state is ParentRecommendationError) {
            return Center(
              child: Text(
                state.message,
                style: GoogleFonts.outfit(color: _textSecondary),
              ),
            );
          }
          if (state is ParentRecommendationLoaded) {
            return _buildLoadedView(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, ParentRecommendationLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          SharedCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 16,
            color: _primary.withOpacity(0.08),
            border: Border.all(color: _primary.withOpacity(0.15)),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: _primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Rekomendasi di bawah ini dibuat otomatis oleh AI berdasarkan data performa fokus dan nilai kuis ${state.childName}.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _primaryDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Langkah Praktis Pendampingan',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lakukan aktivitas sederhana ini bersama anak di rumah untuk menunjang belajarnya:',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.recommendations.length,
            itemBuilder: (context, index) {
              final recommendation = state.recommendations[index];
              return _buildRecommendationCard(recommendation);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendationModel recommendation) {
    final catColor = _getCategoryColor(recommendation.category);
    final catIcon = _getCategoryIcon(recommendation.iconType);

    return SharedCard(
      color: _cardBg,
      margin: const EdgeInsets.only(bottom: 18),
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: catColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          recommendation.category,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: catColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        recommendation.title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Diagnosis Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              recommendation.recommendationText,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Action Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.04),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(
                  color: _primary.withOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.home_work_rounded,
                  color: _primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Langkah Konkrit di Rumah:',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation.actionStep,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: _textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'biologi':
        return const Color(0xFF4CAF50);
      case 'matematika':
        return const Color(0xFF3F51B5);
      case 'fokus membaca':
        return const Color(0xFFFF9800);
      case 'kebiasaan belajar':
        return const Color(0xFFE91E63);
      default:
        return _primary;
    }
  }

  IconData _getCategoryIcon(String iconType) {
    switch (iconType) {
      case 'biology':
        return Icons.biotech_rounded;
      case 'math':
        return Icons.calculate_rounded;
      case 'focus':
        return Icons.center_focus_strong_rounded;
      case 'habit':
        return Icons.calendar_today_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }
}
