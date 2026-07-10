import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../bloc/learning_report/learning_report_bloc.dart';
import '../../bloc/learning_report/learning_report_event.dart';
import '../../bloc/learning_report/learning_report_state.dart';

class LearningReportPage extends StatelessWidget {
  const LearningReportPage({super.key});

  // ── Palette ──
  static const Color _primary = Color(0xFF2E7D6F);
  static const Color _primaryDark = Color(0xFF1B5E50);
  static const Color _surface = Color(0xFFF5FAF8);
  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF1A3C34);
  static const Color _textSecondary = Color(0xFF5F7B74);
  static const Color _chartLine = Color(0xFF5C6BC0);
  static const Color _chartDot = Color(0xFF3F51B5);
  static const Color _passedColor = Color(0xFF43A047);
  static const Color _failedColor = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LearningReportBloc()
        ..add(const LoadLearningReport(studentUid: 'dummy_student')),
      child: Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          title: Text(
            'Laporan Akademik',
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
        body: BlocBuilder<LearningReportBloc, LearningReportState>(
          builder: (context, state) {
            if (state is LearningReportLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _primary),
                    const SizedBox(height: 16),
                    Text('Memuat laporan...', style: GoogleFonts.outfit(color: _textSecondary)),
                  ],
                ),
              );
            }
            if (state is LearningReportError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: _failedColor),
                    const SizedBox(height: 12),
                    Text(state.message, style: GoogleFonts.outfit(color: _textSecondary)),
                  ],
                ),
              );
            }
            if (state is LearningReportLoaded) {
              return _buildLoadedView(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TAMPILAN UTAMA
  // ═══════════════════════════════════════════════
  Widget _buildLoadedView(BuildContext context, LearningReportLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. RINGKASAN STATISTIK ──
          _buildSummaryCards(state),
          const SizedBox(height: 24),

          // ── 2. GRAFIK TREN KUIS UTAMA ──
          _buildSectionTitle('📈 Tren Nilai Kuis Utama'),
          const SizedBox(height: 4),
          Text(
            'Grafik perubahan skor kuis utama dari waktu ke waktu',
            style: GoogleFonts.outfit(fontSize: 12, color: _textSecondary),
          ),
          const SizedBox(height: 16),
          _buildTrendChart(state),
          const SizedBox(height: 28),

          // ── 3. RIWAYAT KUIS LENGKAP ──
          _buildSectionTitle('📋 Riwayat Kuis Lengkap'),
          const SizedBox(height: 12),
          _buildQuizHistoryList(state),
          const SizedBox(height: 28),

          // ── 4. TOMBOL EKSPOR PDF ──
          _buildExportButton(context, state),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ═══════════════════════════════
  //  1. RINGKASAN STATISTIK
  // ═══════════════════════════════
  Widget _buildSummaryCards(LearningReportLoaded state) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            icon: Icons.quiz_rounded,
            label: 'Total Kuis',
            value: '${state.totalQuizzes}',
            color: _chartLine,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniCard(
            icon: Icons.check_circle_rounded,
            label: 'Lulus',
            value: '${state.totalPassed}',
            color: _passedColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniCard(
            icon: Icons.trending_up_rounded,
            label: 'Rata-Rata',
            value: '${state.averageScore.toStringAsFixed(0)}%',
            color: _primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════
  //  2. GRAFIK TREN (fl_chart)
  // ═══════════════════════════════
  Widget _buildTrendChart(LearningReportLoaded state) {
    if (state.trendData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('Belum ada data kuis utama.',
              style: GoogleFonts.outfit(color: _textSecondary)),
        ),
      );
    }

    final spots = state.trendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.scorePercent);
    }).toList();

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
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
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 25,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: _textSecondary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= state.trendData.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.trendData[index].label,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: _textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: _chartLine,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 5,
                  color: _cardBg,
                  strokeWidth: 3,
                  strokeColor: _chartDot,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _chartLine.withOpacity(0.08),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.spotIndex;
                  final label = index < state.trendData.length
                      ? state.trendData[index].label
                      : '';
                  return LineTooltipItem(
                    '$label\n${spot.y.toStringAsFixed(0)}%',
                    GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════
  //  3. RIWAYAT KUIS LENGKAP
  // ═══════════════════════════════
  Widget _buildQuizHistoryList(LearningReportLoaded state) {
    if (state.quizHistory.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Belum ada riwayat kuis.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: _textSecondary),
        ),
      );
    }

    return Column(
      children: state.quizHistory.map((quiz) {
        final dateFormatted = DateFormat('dd MMM yyyy', 'id').format(quiz.date);
        final typeLabel = quiz.type == 'quiz_utama' ? 'Kuis Utama' : 'Quick Check';
        final typeColor = quiz.type == 'quiz_utama' ? Colors.deepPurple : Colors.blue.shade700;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: quiz.passed
                  ? _passedColor.withOpacity(0.2)
                  : _failedColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Score circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: quiz.passed
                      ? _passedColor.withOpacity(0.1)
                      : _failedColor.withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    '${quiz.percentage.toInt()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: quiz.passed ? _passedColor : _failedColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.materialTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: typeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.calendar_today_rounded, size: 12, color: _textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          dateFormatted,
                          style: GoogleFonts.outfit(fontSize: 11, color: _textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Skor: ${quiz.score}/${quiz.totalQuestions}',
                      style: GoogleFonts.outfit(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              // Pass/Fail badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: quiz.passed
                      ? _passedColor.withOpacity(0.1)
                      : _failedColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quiz.passed ? '✓ Lulus' : '✗ Gagal',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: quiz.passed ? _passedColor : _failedColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════
  //  4. TOMBOL EKSPOR PDF
  // ═══════════════════════════════
  Widget _buildExportButton(BuildContext context, LearningReportLoaded state) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () => _generateAndPrintPdf(context, state),
        icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
        label: Text(
          'Unduh Raport PDF',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // ═══════════════════════════════
  //  PDF GENERATOR
  // ═══════════════════════════════
  Future<void> _generateAndPrintPdf(
    BuildContext context,
    LearningReportLoaded state,
  ) async {
    final pdf = pw.Document();
    final dateNow = DateFormat('dd MMMM yyyy', 'id').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) => [
          // ── HEADER ──
          pw.Center(
            child: pw.Text(
              'SI-FOKUS',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1B5E50'),
              ),
            ),
          ),
          pw.Center(
            child: pw.Text(
              'Raport Akademik Siswa',
              style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 2, color: PdfColor.fromHex('#2E7D6F')),
          pw.SizedBox(height: 16),

          // ── INFO SISWA ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _pdfInfoRow('Nama Siswa', state.childName),
                  _pdfInfoRow('Tanggal Cetak', dateNow),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _pdfInfoRow('Total Kuis', '${state.totalQuizzes}'),
                  _pdfInfoRow('Rata-Rata Skor', '${state.averageScore.toStringAsFixed(1)}%'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── STATISTIK ──
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F0F7F5'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfStatBox('Total Kuis', '${state.totalQuizzes}'),
                _pdfStatBox('Lulus', '${state.totalPassed}'),
                _pdfStatBox('Gagal', '${state.totalQuizzes - state.totalPassed}'),
                _pdfStatBox('Rata-Rata', '${state.averageScore.toStringAsFixed(0)}%'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // ── TABEL RIWAYAT KUIS ──
          pw.Text(
            'Riwayat Kuis',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A3C34'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#2E7D6F'),
            ),
            headerAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.center,
            cellHeight: 28,
            headers: ['Materi', 'Tipe', 'Skor', 'Persentase', 'Status', 'Tanggal'],
            data: state.quizHistory.map((q) {
              return [
                q.materialTitle,
                q.type == 'quiz_utama' ? 'Kuis Utama' : 'Quick Check',
                '${q.score}/${q.totalQuestions}',
                '${q.percentage.toStringAsFixed(0)}%',
                q.passed ? 'LULUS' : 'GAGAL',
                DateFormat('dd/MM/yy').format(q.date),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 24),

          // ── FOOTER ──
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Dicetak oleh SI-FOKUS • Sistem Informasi Fokus, Observasi, dan Kompetensi Ujian Siswa',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                dateNow,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );

    // Tampilkan dialog preview & print/save PDF
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Raport_${state.childName.replaceAll(' ', '_')}_$dateNow',
    );
  }

  // ── PDF Helper Widgets ──
  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A3C34'),
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfStatBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#2E7D6F'),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  // ═══════════════════════════════
  //  HELPERS
  // ═══════════════════════════════
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
}
