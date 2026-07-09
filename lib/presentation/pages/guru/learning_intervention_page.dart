import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/intervention_model.dart';
import '../../bloc/intervention/intervention_bloc.dart';
import '../../bloc/intervention/intervention_event.dart';
import '../../bloc/intervention/intervention_state.dart';

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
      appBar: AppBar(
        title: const Text('AI Intervensi Pembelajaran'),
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Early Warning Box (Peringatan Dini)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: warningBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: warningBorder, width: 1.5),
                    ),
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
                  Card(
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
                              Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              const Text(
                                'Rekomendasi Kelas AI',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Daftar siswa dengan performa di bawah ambang batas lulus kuis. Guru dapat mengirimkan notifikasi pengingat remedial secara instan.',
                    style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  if (intervention.individualInterventions.isEmpty) ...[
                    const Card(
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
