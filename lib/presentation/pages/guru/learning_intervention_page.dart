import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/intervention_model.dart';
import '../../bloc/intervention/intervention_bloc.dart';
import '../../bloc/intervention/intervention_event.dart';
import '../../bloc/intervention/intervention_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/shared_ui_kit.dart';

class LearningInterventionPage extends StatefulWidget {
  final String classId;
  final String materialId;

  const LearningInterventionPage({
    super.key,
    required this.classId,
    required this.materialId,
  });

  @override
  State<LearningInterventionPage> createState() => _LearningInterventionPageState();
}

class _LearningInterventionPageState extends State<LearningInterventionPage> {
  @override
  void initState() {
    super.initState();
    context.read<InterventionBloc>().add(
          FetchInterventionDataEvent(
            classId: widget.classId,
            materialId: widget.materialId,
          ),
        );
  }

  void _onSendReminder(IndividualInterventionModel indiv) {
    context.read<InterventionBloc>().add(
          SendNotificationRequested(
            studentId: indiv.studentId,
            studentName: indiv.studentName,
            message: indiv.message,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // HSL Colors untuk Early Warning Box (Yellow/Amber Theme)
    final warningBg = const HSLColor.fromAHSL(1.0, 45, 0.90, 0.94).toColor();
    final warningBorder = const HSLColor.fromAHSL(1.0, 45, 0.80, 0.70).toColor();
    final warningText = const HSLColor.fromAHSL(1.0, 45, 0.90, 0.25).toColor();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const SharedAppBar(
        title: 'AI Intervensi Pembelajaran',
      ),
      body: BlocConsumer<InterventionBloc, InterventionState>(
        listener: (context, state) {
          if (state is NotificationSendSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Notifikasi pengingat remedial berhasil terkirim ke ${state.studentName}!'),
                backgroundColor: theme.colorScheme.secondary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is InterventionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is InterventionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InterventionLoaded) {
            final intervention = state.intervention;

            if (intervention.individualInterventions.isEmpty &&
                (intervention.summaryAlert.contains('Belum ada data') || intervention.summaryAlert.isEmpty)) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Belum Ada Data Aktivitas',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Modul ini baru saja diunggah. Rekomendasi intervensi pembelajaran kognitif AI akan dihasilkan secara otomatis setelah siswa kelas mulai membaca materi atau mengerjakan kuis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Kembali ke Rincian Kelas'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Early Warning Box (Peringatan Dini)
                  SharedCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 16,
                    color: warningBg,
                    border: Border.all(color: warningBorder, width: 1.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: warningText, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Peringatan Dini Kognitif',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: warningText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                intervention.summaryAlert,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: warningText.withValues(alpha: 0.85),
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

                  // 2. AI Recommendations Card
                  SharedCard(
                    borderRadius: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryLight),
                              const SizedBox(width: 8),
                              Text(
                                'Rekomendasi Kelas AI',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimaryLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: intervention.recommendations.map((rec) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: theme.colorScheme.secondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        rec,
                                        style: const TextStyle(fontSize: 13, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Individual Remedial List
                  Text(
                    'Siswa Butuh Remedial',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Daftar siswa dengan performa di bawah ambang batas lulus kuis. Guru dapat mengirimkan notifikasi pengingat remedial secara instan.',
                    style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  if (intervention.individualInterventions.isEmpty) ...[
                    const SharedCard(
                      borderRadius: 16,
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'Selamat! Seluruh siswa lulus ambang kuis.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    )
                  ] else ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: intervention.individualInterventions.length,
                      itemBuilder: (context, index) {
                        final indiv = intervention.individualInterventions[index];
                        return SharedCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.zero,
                          borderRadius: 16,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                indiv.studentName.substring(0, 1),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              indiv.studentName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                indiv.message,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.notifications_active_rounded,
                                color: theme.colorScheme.secondary,
                              ),
                              tooltip: 'Kirim Notifikasi Pengingat',
                              onPressed: () => _onSendReminder(indiv),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          }

          return const Center(child: Text('Tidak ada data rekomendasi intervensi.'));
        },
      ),
    );
  }
}
