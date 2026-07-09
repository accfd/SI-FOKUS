import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/student_recommendation/student_recommendation_bloc.dart';
import '../../bloc/student_recommendation/student_recommendation_event.dart';
import '../../bloc/student_recommendation/student_recommendation_state.dart';
import '../../../../data/models/student_recommendation_model.dart';

class StudentRecommendationWidget extends StatefulWidget {
  final String materialId;

  const StudentRecommendationWidget({
    Key? key,
    required this.materialId,
  }) : super(key: key);

  @override
  State<StudentRecommendationWidget> createState() =>
      _StudentRecommendationWidgetState();
}

class _StudentRecommendationWidgetState
    extends State<StudentRecommendationWidget> {
  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  void _loadRecommendation() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<StudentRecommendationBloc>().add(
            LoadStudentRecommendation(
              studentId: authState.user.uid,
              materialId: widget.materialId,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentRecommendationBloc, StudentRecommendationState>(
      builder: (context, state) {
        if (state is StudentRecommendationLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is StudentRecommendationError) {
          return _buildInfoCard(
            title: 'Oops!',
            message: state.message,
            icon: Icons.error_outline,
            color: Colors.red.shade100,
            iconColor: Colors.red,
          );
        }

        if (state is StudentRecommendationEmpty) {
          return _buildInfoCard(
            title: 'Belum Ada Rekomendasi',
            message:
                'Selesaikan Kuis Utama terlebih dahulu untuk mendapatkan analisis dan rekomendasi personal dari AI.',
            icon: Icons.lightbulb_outline,
            color: Colors.indigo.shade50,
            iconColor: Colors.indigo,
          );
        }

        if (state is StudentRecommendationLoaded) {
          return _buildRecommendationContent(state.recommendation);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildRecommendationContent(StudentRecommendationModel data) {
    // Definisi HSL Premium Soft Colors
    final Color softRed = HSLColor.fromAHSL(1.0, 0, 0.75, 0.96).toColor();
    final Color borderRed = HSLColor.fromAHSL(1.0, 0, 0.60, 0.85).toColor();
    final Color textRed = HSLColor.fromAHSL(1.0, 0, 0.70, 0.40).toColor();

    final Color softGreen = HSLColor.fromAHSL(1.0, 140, 0.60, 0.95).toColor();
    final Color borderGreen = HSLColor.fromAHSL(1.0, 140, 0.50, 0.80).toColor();
    final Color textGreen = HSLColor.fromAHSL(1.0, 140, 0.60, 0.35).toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Text(
            'Analisis Belajarmu 🧠',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade900,
            ),
          ),
        ),
        
        // Card Kelemahan (Perlu Dipelajari Ulang)
        if (data.reLearnTopics.isNotEmpty)
          _buildAnalysisCard(
            title: 'Materi yang Perlu Dipelajari Ulang',
            icon: Icons.trending_down_rounded,
            items: data.reLearnTopics,
            backgroundColor: softRed,
            borderColor: borderRed,
            textColor: textRed,
          ),

        const SizedBox(height: 12),

        // Card Kelebihan (Kekuatan)
        if (data.strengths.isNotEmpty)
          _buildAnalysisCard(
            title: 'Kelebihan Belajarmu',
            icon: Icons.trending_up_rounded,
            items: data.strengths,
            backgroundColor: softGreen,
            borderColor: borderGreen,
            textColor: textGreen,
          ),

        const SizedBox(height: 20),

        // Card Metode Belajar yang Disarankan
        if (data.recommendedMethod.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade50, Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.purple.shade400,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saran AI Spesial Untukmu',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.recommendedMethod,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAnalysisCard({
    required String title,
    required IconData icon,
    required List<String> items,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: textColor.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
