import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/analytics_model.dart';
import '../../bloc/analytics/analytics_bloc.dart';
import '../../bloc/analytics/analytics_event.dart';
import '../../bloc/analytics/analytics_state.dart';

class LearningAnalyticsPage extends StatefulWidget {
  final String classId;

  const LearningAnalyticsPage({
    super.key,
    required this.classId,
  });

  @override
  State<LearningAnalyticsPage> createState() => _LearningAnalyticsPageState();
}

class _LearningAnalyticsPageState extends State<LearningAnalyticsPage> {
  String _timeRange = '30'; // '7' | '30' | 'all'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<AnalyticsBloc>().add(FetchClassAnalyticsHistory(widget.classId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis Tren Belajar Kelas'),
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AnalyticsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data analitik',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(state.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          if (state is AnalyticsLoaded) {
            final data = state.analytics;

            final filteredTrends = _filterQuizTrends(data.quizTrends);

            final filteredStudents = data.studentSummaries
                .where((s) => s.studentName.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTimeRangeFilter(theme),
                  const SizedBox(height: 20),

                  _buildQuizTrendLineChart(theme, filteredTrends),
                  const SizedBox(height: 20),

                  _buildCorrelationSection(theme, data.readingStats),
                  const SizedBox(height: 24),

                  _buildStudentListSection(theme, filteredStudents),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }

          return const Center(child: Text('Tidak ada laporan analitik belajar kelas.'));
        },
      ),
    );
  }

  Widget _buildTimeRangeFilter(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildFilterButton('7 Hari', '7', theme),
            _buildFilterButton('30 Hari', '30', theme),
            _buildFilterButton('Semua', 'all', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String value, ThemeData theme) {
    final isSelected = _timeRange == value;
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? theme.colorScheme.primary : Colors.transparent,
        foregroundColor: isSelected ? Colors.white : theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onPressed: () {
        setState(() {
          _timeRange = value;
        });
      },
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  List<QuizTrendPoint> _filterQuizTrends(List<QuizTrendPoint> trends) {
    if (_timeRange == '7') {
      return trends.take(3).toList();
    }
    return trends;
  }

  Widget _buildQuizTrendLineChart(ThemeData theme, List<QuizTrendPoint> trends) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Perkembangan Nilai Kuis Kelas',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Menyajikan grafik perkembangan nilai kuis rata-rata seluruh siswa kelas.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 220,
              child: trends.isEmpty
                  ? const Center(child: Text('Data tidak cukup.'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx >= 0 && idx < trends.length) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      trends[idx].quizName,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineTouchData: LineTouchData(enabled: true),
                        minY: 50,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(trends.length, (idx) {
                              return FlSpot(idx.toDouble(), trends[idx].averageScore);
                            }),
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationSection(ThemeData theme, List<ModuleReadingStat> stats) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.query_stats_rounded, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Korelasi Membaca vs Nilai Kuis',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Perbandingan rata-rata menit belajar siswa membaca materi dengan skor kuis yang diperoleh.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),

            Column(
              children: stats.map((stat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.moduleTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      
                      Row(
                        children: [
                          const SizedBox(
                            width: 100,
                            child: Text('Durasi Baca', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: stat.avgReadingMinutes / 60.0,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                              color: theme.colorScheme.secondary,
                              backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${stat.avgReadingMinutes.toStringAsFixed(1)} mnt',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const SizedBox(
                            width: 100,
                            child: Text('Rata Nilai Kuis', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: stat.avgQuizScore / 100.0,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                              color: theme.colorScheme.primary,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            stat.avgQuizScore.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentListSection(ThemeData theme, List<StudentAnalyticsSummary> students) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Perkembangan Individu Siswa',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        TextFormField(
          decoration: const InputDecoration(
            hintText: 'Cari Nama Siswa...',
            prefixIcon: Icon(Icons.search_rounded),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
        ),
        const SizedBox(height: 16),

        if (students.isEmpty) ...[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('Tidak ada siswa yang cocok.')),
            ),
          )
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                    child: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary),
                  ),
                  title: Text(
                    student.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Modul selesai: ${student.completedModulesCount}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        student.avgQuizScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: student.avgQuizScore >= 75
                              ? theme.colorScheme.secondary
                              : Colors.orange.shade800,
                        ),
                      ),
                      const Text(
                        'Rerata Kuis',
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
