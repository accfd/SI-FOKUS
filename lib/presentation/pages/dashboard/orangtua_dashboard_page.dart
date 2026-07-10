import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/parent_monitoring/parent_monitoring_bloc.dart';
import '../../bloc/parent_monitoring/parent_monitoring_event.dart';
import '../../bloc/parent_monitoring/parent_monitoring_state.dart';

class OrangTuaDashboardPage extends StatelessWidget {
  const OrangTuaDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = ParentMonitoringBloc();
        // Ambil UID parent dari AuthBloc, gunakan 'dummy' jika belum login
        final authState = context.read<AuthBloc>().state;
        String parentUid = 'dummy_parent';
        if (authState is Authenticated) {
          parentUid = authState.user.uid;
        }
        bloc.add(LoadChildData(parentUid: parentUid));
        return bloc;
      },
      child: const _OrangTuaDashboardView(),
    );
  }
}

class _OrangTuaDashboardView extends StatelessWidget {
  const _OrangTuaDashboardView();

  // ── Palette warna menenangkan untuk orang tua ──
  static const Color _primary = Color(0xFF2E7D6F);      // Teal hijau tenang
  static const Color _primaryDark = Color(0xFF1B5E50);   // Teal gelap
  static const Color _surface = Color(0xFFF5FAF8);        // Off-white kehijauan
  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF1A3C34);
  static const Color _textSecondary = Color(0xFF5F7B74);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Text(
          'SI-FOKUS Orang Tua',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
              context.go('/login');
            },
          ),
        ],
      ),
      body: BlocBuilder<ParentMonitoringBloc, ParentMonitoringState>(
        builder: (context, state) {
          if (state is ParentMonitoringLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _primary),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat data anak...',
                    style: GoogleFonts.outfit(
                      color: _textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ParentMonitoringNoChild) {
            return _buildNoChildView();
          }

          if (state is ParentMonitoringError) {
            return _buildErrorView(state.message);
          }

          if (state is ParentMonitoringLoaded) {
            return _buildLoadedView(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TAMPILAN UTAMA SAAT DATA ANAK BERHASIL DIMUAT
  // ═══════════════════════════════════════════════
  Widget _buildLoadedView(BuildContext context, ParentMonitoringLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. HERO CARD: Profil Anak ──
          _buildChildProfileCard(state),
          const SizedBox(height: 24),

          // ── 2. STATISTIK RINGKAS ──
          _buildSectionTitle('Ringkasan Belajar'),
          const SizedBox(height: 12),
          _buildStatsRow(state),
          const SizedBox(height: 24),

          // ── 3. MENU PINTAS ──
          _buildSectionTitle('Fitur Pemantauan'),
          const SizedBox(height: 12),
          _buildShortcutMenu(context),
          const SizedBox(height: 24),

          // ── 4. AKTIVITAS TERAKHIR ──
          _buildSectionTitle('Aktivitas Terakhir'),
          const SizedBox(height: 12),
          _buildRecentActivities(state),
          const SizedBox(height: 24),

          // ── 5. HASIL KUIS ──
          _buildSectionTitle('Hasil Kuis'),
          const SizedBox(height: 12),
          _buildQuizResults(state),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ═════════════════════════════
  //  HERO CARD: PROFIL ANAK
  // ═════════════════════════════
  Widget _buildChildProfileCard(ParentMonitoringLoaded state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar anak
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.child_care_rounded,
                  size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),

          // Nama Anak
          Text(
            state.childName,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.className,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),

          // XP / Level / Badges
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProfileStat(
                  icon: Icons.bolt_rounded,
                  value: '${state.childXp}',
                  label: 'XP',
                  color: Colors.amber,
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildProfileStat(
                  icon: Icons.military_tech_rounded,
                  value: 'Lv.${state.childLevel}',
                  label: 'Level',
                  color: Colors.lightBlueAccent,
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildProfileStat(
                  icon: Icons.workspace_premium_rounded,
                  value: '${state.childBadges.length}',
                  label: 'Badges',
                  color: Colors.orangeAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════
  //  STATISTIK RINGKAS
  // ═════════════════════════════
  Widget _buildStatsRow(ParentMonitoringLoaded state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.visibility_rounded,
            title: 'Skor Fokus',
            value: '${state.averageFocusScore.toStringAsFixed(0)}%',
            color: _getFocusColor(state.averageFocusScore),
            subtitle: _getFocusLabel(state.averageFocusScore),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.quiz_rounded,
            title: 'Kuis Lulus',
            value: '${state.quizzesPassed}/${state.quizzesPassed + state.quizzesFailed}',
            color: Colors.blue.shade600,
            subtitle: 'Total ujian',
          ),
        ),
      ],
    );
  }

  Color _getFocusColor(double score) {
    if (score >= 80) return const Color(0xFF43A047);
    if (score >= 60) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  String _getFocusLabel(double score) {
    if (score >= 80) return 'Sangat Baik';
    if (score >= 60) return 'Cukup Baik';
    return 'Perlu Perhatian';
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════
  //  MENU PINTAS
  // ═════════════════════════════
  Widget _buildShortcutMenu(BuildContext context) {
    final shortcuts = [
      _ShortcutItem(
        icon: Icons.assessment_rounded,
        title: 'Laporan\nAkademik',
        color: const Color(0xFF5C6BC0),
        onTap: () => context.go('/dashboard/orangtua/learning-report'),
      ),
      _ShortcutItem(
        icon: Icons.favorite_rounded,
        title: 'Kesehatan\nBelajar',
        color: const Color(0xFFEF5350),
        onTap: () => context.go('/dashboard/orangtua/learning-health'),
      ),
      _ShortcutItem(
        icon: Icons.psychology_rounded,
        title: 'Rekomendasi\nPendampingan',
        color: const Color(0xFFFF9800),
        onTap: () => _showComingSoon(context, 'Rekomendasi Pendampingan'),
      ),
      _ShortcutItem(
        icon: Icons.emoji_events_rounded,
        title: 'Potensi\n& Bakat',
        color: const Color(0xFF26A69A),
        onTap: () => _showComingSoon(context, 'Potensi & Bakat'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: shortcuts.map((item) {
        return InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                const Spacer(),
                Text(
                  item.title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔜 $featureName akan segera hadir!',
          style: GoogleFonts.outfit(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _primaryDark,
      ),
    );
  }

  // ═════════════════════════════
  //  AKTIVITAS TERAKHIR
  // ═════════════════════════════
  Widget _buildRecentActivities(ParentMonitoringLoaded state) {
    if (state.recentActivities.isEmpty) {
      return _buildEmptyCard('Belum ada aktivitas belajar tercatat.');
    }

    return Column(
      children: state.recentActivities.map((activity) {
        final focusScore = (activity['focusScore'] as num?)?.toDouble() ?? 0;
        final readMin = ((activity['readDurationSec'] as num?) ?? 0) ~/ 60;
        final title = activity['materialTitle'] as String? ?? 'Materi';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Indikator fokus
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getFocusColor(focusScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${focusScore.toInt()}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getFocusColor(focusScore),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Membaca $readMin menit • Fokus ${focusScore.toInt()}%',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═════════════════════════════
  //  HASIL KUIS
  // ═════════════════════════════
  Widget _buildQuizResults(ParentMonitoringLoaded state) {
    if (state.quizResults.isEmpty) {
      return _buildEmptyCard('Belum ada hasil kuis.');
    }

    return Column(
      children: state.quizResults.map((quiz) {
        final title = quiz['materialTitle'] as String? ?? 'Kuis';
        final type = quiz['type'] as String? ?? 'quick_check';
        final score = quiz['score'] as int? ?? 0;
        final total = quiz['totalQuestions'] as int? ?? 0;
        final passed = quiz['passed'] as bool? ?? false;

        final typeLabel = type == 'quiz_utama' ? 'Kuis Utama' : 'Quick Check';
        final scorePercent = total > 0 ? ((score / total) * 100).toInt() : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: passed
                  ? const Color(0xFF43A047).withOpacity(0.3)
                  : Colors.red.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: passed
                      ? const Color(0xFF43A047).withOpacity(0.1)
                      : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  passed
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: passed
                      ? const Color(0xFF43A047)
                      : Colors.red.shade400,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: type == 'quiz_utama'
                                ? Colors.deepPurple.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: type == 'quiz_utama'
                                  ? Colors.deepPurple
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Skor: $score/$total ($scorePercent%)',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: passed
                      ? const Color(0xFF43A047).withOpacity(0.1)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  passed ? 'Lulus' : 'Gagal',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: passed
                        ? const Color(0xFF43A047)
                        : Colors.red.shade600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═════════════════════════════
  //  HELPERS
  // ═════════════════════════════
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _textPrimary,
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: _textSecondary,
        ),
      ),
    );
  }

  // ═════════════════════════════
  //  STATE VIEWS
  // ═════════════════════════════
  Widget _buildNoChildView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.link_off_rounded,
                size: 56,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Anak Terhubung',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hubungkan akun Anda dengan akun siswa anak menggunakan Parent Access Code yang tersedia di profil siswa.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: _textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Model internal untuk menu pintas ──
class _ShortcutItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}
