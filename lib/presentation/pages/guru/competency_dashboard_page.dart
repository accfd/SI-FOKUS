import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/competency_model.dart';
import '../../bloc/competency/competency_bloc.dart';
import '../../bloc/competency/competency_event.dart';
import '../../bloc/competency/competency_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/shared_ui_kit.dart';

class CompetencyDashboardPage extends StatefulWidget {
  final String classId;

  const CompetencyDashboardPage({
    super.key,
    required this.classId,
  });

  @override
  State<CompetencyDashboardPage> createState() => _CompetencyDashboardPageState();
}

class _CompetencyDashboardPageState extends State<CompetencyDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompetencyBloc>().add(FetchClassCompetencyData(widget.classId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const SharedAppBar(
        title: 'Dasbor Kompetensi Siswa (AI)',
      ),
      body: BlocBuilder<CompetencyBloc, CompetencyState>(
        builder: (context, state) {
          if (state is CompetencyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CompetencyError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data kompetensi',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(state.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          if (state is CompetencyDataLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Banner
                  _buildHeaderBanner(theme),
                  const SizedBox(height: 20),

                  // Grid: Rerata Kelas & Radar Chart
                  _buildTopGrid(theme, state.competency),
                  const SizedBox(height: 20),

                  // Horizontal Bar Chart Card (Mistake rate)
                  _buildMistakeTopicsCard(theme, state.competency.highestMistakeTopics),
                  const SizedBox(height: 20),

                  // Recommendation Card
                  _buildRecommendationCard(theme, state.competency.highestMistakeTopics),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }

          return const Center(child: Text('Tidak ada data kompetensi kelas.'));
        },
      ),
    );
  }

  Widget _buildHeaderBanner(ThemeData theme) {
    return SharedCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      color: AppColors.primaryLight,
      border: Border.all(color: AppColors.primaryLight, width: 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analisis Kognitif AI',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 4),
                Text(
                  'Gemini AI membaca hasil pengerjaan kuis siswa untuk memetakan kelemahan materi kelas secara presisi.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopGrid(ThemeData theme, CompetencyModel comp) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isMobile = width < 600;

        final averageCard = _buildClassAverageCard(theme, comp.averageScore);
        final radarCard = _buildCompetencyRadarCard(theme, comp.competencyMastery);

        if (isMobile) {
          return Column(
            children: [
              averageCard,
              const SizedBox(height: 20),
              radarCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: averageCard),
            const SizedBox(width: 20),
            Expanded(flex: 3, child: radarCard),
          ],
        );
      },
    );
  }

  Widget _buildClassAverageCard(ThemeData theme, double average) {
    return SharedCard(
      borderRadius: 20,
      child: Container(
        height: 280,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rata-rata Kuis Kelas',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: average / 100,
                      strokeWidth: 16,
                      color: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        average.toStringAsFixed(1),
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Text(
                        'Skor Maks 100',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: average >= 75
                    ? theme.colorScheme.secondary.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                average >= 75 ? 'Performa Baik' : 'Butuh Intervensi',
                style: TextStyle(
                  color: average >= 75 ? theme.colorScheme.secondary : Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetencyRadarCard(ThemeData theme, Map<String, double> mastery) {
    final entries = mastery.entries.toList();

    return SharedCard(
      borderRadius: 20,
      child: Container(
        height: 280,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sebaran Penguasaan Kompetensi',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      fillColor: AppColors.primaryLight.withValues(alpha: 0.15),
                      borderColor: AppColors.primaryLight,
                      entryRadius: 4,
                      borderWidth: 2,
                      dataEntries: entries.map((e) => RadarEntry(value: e.value * 100)).toList(),
                    ),
                  ],
                  radarShape: RadarShape.polygon,
                  gridBorderData: BorderSide(color: Colors.grey.shade300, width: 1),
                  tickBorderData: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ticksTextStyle: const TextStyle(fontSize: 7, color: Colors.grey),
                  tickCount: 4,
                  titlePositionPercentageOffset: 0.15,
                  getTitle: (index, angle) {
                    if (index >= 0 && index < entries.length) {
                      return RadarChartTitle(
                        text: entries[index].key,
                        angle: angle,
                      );
                    }
                    return const RadarChartTitle(text: '');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMistakeTopicsCard(ThemeData theme, List<MistakeTopicModel> mistakeTopics) {
    return SharedCard(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Row(
              children: [
                const Icon(Icons.report_problem_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  'Materi dengan Tingkat Kesalahan Tertinggi',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimaryLight),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Menyajikan tingkat kesalahan rata-rata siswa dalam menjawab soal per sub-materi.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 32),

            // Bar Chart Area
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < mistakeTopics.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                'Topik ${idx + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(mistakeTopics.length, (idx) {
                    final item = mistakeTopics[idx];
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: item.errorRate,
                          color: theme.colorScheme.error,
                          width: 32,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Legend detail
            Column(
              children: List.generate(mistakeTopics.length, (idx) {
                final item = mistakeTopics[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Topik ${idx + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.topic,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${item.errorRate.toStringAsFixed(1)}% Error',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      );
  }

  Widget _buildRecommendationCard(ThemeData theme, List<MistakeTopicModel> topics) {
    final highestTopic = topics.isNotEmpty ? topics.first.topic : '-';

    return SharedCard(
      borderRadius: 20,
      color: AppColors.primaryLight.withValues(alpha: 0.05),
      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.15)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Text(
                  'Rekomendasi Pembelajaran AI',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Berdasarkan tingginya persentase kesalahan siswa, disarankan bagi Anda untuk melakukan pembelajaran remedial atau menjelaskan kembali sub-topik "$highestTopic" menggunakan metode visual/grafik bantuan.',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      );
  }
}
