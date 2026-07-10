import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/learning_profile/learning_profile_bloc.dart';
import '../../bloc/learning_profile/learning_profile_event.dart';
import '../../bloc/learning_profile/learning_profile_state.dart';
import '../../../../data/models/digital_learning_profile_model.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/shared_ui_kit.dart';

class ProfileSiswaPage extends StatefulWidget {
  const ProfileSiswaPage({Key? key}) : super(key: key);

  @override
  State<ProfileSiswaPage> createState() => _ProfileSiswaPageState();
}

class _ProfileSiswaPageState extends State<ProfileSiswaPage> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<LearningProfileBloc>().add(
            LoadDigitalLearningProfile(authState.user.uid),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const SharedAppBar(
        title: 'Digital Learning Profile',
      ),
      body: BlocBuilder<LearningProfileBloc, LearningProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProfileError) {
            return Center(
              child: Text(
                state.message,
                style: GoogleFonts.outfit(color: Colors.red),
              ),
            );
          }
          if (state is ProfileLoaded) {
            return _buildProfileContent(state.profile);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildProfileContent(DigitalLearningProfileModel profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analisis Kualitatif',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildQualitativeGrid(profile),
          
          const SizedBox(height: 32),
          
          Text(
            'Tren Fokus Belajar',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildFocusLineChart(profile.focusTrend),
          
          const SizedBox(height: 32),
          
          Text(
            'Konsistensi Waktu Belajar (Jam)',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildConsistencyBarChart(profile.consistencyTrend),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQualitativeGrid(DigitalLearningProfileModel profile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsif grid: 1 kolom jika sempit, 2 kolom jika lebar
        int crossAxisCount = constraints.maxWidth > 500 ? 3 : 1;
        if (constraints.maxWidth > 400 && constraints.maxWidth <= 500) {
           crossAxisCount = 2;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildStatCard(
              title: 'Paling Dikuasai',
              value: profile.strongestMaterial,
              icon: Icons.star_rounded,
              color: AppColors.primaryLight,
              bgColor: AppColors.primaryLight.withValues(alpha: 0.08),
            ),
            _buildStatCard(
              title: 'Paling Sulit',
              value: profile.weakestMaterial,
              icon: Icons.warning_rounded,
              color: AppColors.error,
              bgColor: AppColors.error.withValues(alpha: 0.08),
            ),
            _buildStatCard(
              title: 'Media Efektif',
              value: profile.mostEffectiveMedia,
              icon: Icons.play_circle_filled_rounded,
              color: AppColors.accentLight,
              bgColor: AppColors.accentLight.withValues(alpha: 0.08),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusLineChart(List<FocusDataPoint> data) {
    if (data.isEmpty) return const SizedBox();

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].focusScore));
    }

    return SharedCard(
      borderRadius: 16,
      child: SizedBox(
        height: 250,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, left: 0, top: 16, bottom: 0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    final date = data[value.toInt()].date;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        DateFormat('d MMM').format(date),
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
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
                interval: 20,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.primaryLight,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: AppColors.primaryLight,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primaryLight.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildConsistencyBarChart(List<ConsistencyDataPoint> data) {
    if (data.isEmpty) return const SizedBox();

    return SharedCard(
      borderRadius: 16,
      child: SizedBox(
        height: 250,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, left: 0, top: 16, bottom: 0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10, // Asumsi maksimal 10 jam per minggu, bisa dinamis
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppColors.primaryLight,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY} Jam',
                  GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        data[value.toInt()].weekLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
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
                reservedSize: 30,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data[index].hoursStudied,
                  color: AppColors.primaryLight,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 10,
                    color: AppColors.primaryLight.withValues(alpha: 0.08),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    ),
  ),
);
  }
}
