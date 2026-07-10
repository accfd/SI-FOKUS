import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/assessment_model.dart';
import '../../bloc/assessment/assessment_bloc.dart';
import '../../bloc/assessment/assessment_event.dart';
import '../../bloc/assessment/assessment_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/shared_ui_kit.dart';

class QuizConfigPage extends StatefulWidget {
  final String classId;
  final String materialId;
  final String type; // 'quick_check' | 'quiz_utama'

  const QuizConfigPage({
    super.key,
    required this.classId,
    required this.materialId,
    required this.type,
  });

  @override
  State<QuizConfigPage> createState() => _QuizConfigPageState();
}

class _QuizConfigPageState extends State<QuizConfigPage> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime? _startDate;
  DateTime? _endDate;
  final _durationController = TextEditingController(text: '60');
  bool _isPublished = false;
  String? _assessmentId;
  bool _isInitialized = false;

  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AssessmentBloc>().add(
          FetchAssessmentByMaterial(
            materialId: widget.materialId,
            type: widget.type,
          ),
        );
  }

  @override
  void dispose() {
    _durationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _populateFields(AssessmentModel assessment) {
    if (_isInitialized) return;
    
    setState(() {
      _assessmentId = assessment.assessmentId;
      _startDate = assessment.startDate ?? DateTime.now();
      _endDate = assessment.endDate ?? DateTime.now().add(const Duration(days: 7));
      _durationController.text = assessment.durationMinutes.toString();
      _isPublished = assessment.isPublished;
      
      _startDateController.text = _formatDateTime(_startDate!);
      _endDateController.text = _formatDateTime(_endDate!);
      _isInitialized = true;
    });
  }

  String _formatDateTime(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final initialDate = (isStart ? _startDate : _endDate) ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStart) {
            _startDate = combinedDateTime;
            _startDateController.text = _formatDateTime(combinedDateTime);
          } else {
            _endDate = combinedDateTime;
            _endDateController.text = _formatDateTime(combinedDateTime);
          }
        });
      }
    }
  }

  void _onSave() {
    if (_assessmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data kuis belum tersedia di database.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batas waktu penutupan tidak boleh mendahului waktu pembukaan kuis.'), backgroundColor: Colors.orange),
        );
        return;
      }

      context.read<AssessmentBloc>().add(
            UpdateQuizConfiguration(
              assessmentId: _assessmentId!,
              startDate: _startDate ?? DateTime.now(),
              endDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
              durationMinutes: int.tryParse(_durationController.text) ?? 60,
              isPublished: _isPublished,
              materialId: widget.materialId,
              type: widget.type,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleLabel = widget.type == 'quick_check' ? 'Jadwal Quick Check' : 'Jadwal Kuis Utama';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: SharedAppBar(
        title: titleLabel,
      ),
      body: BlocConsumer<AssessmentBloc, AssessmentState>(
        listener: (context, state) {
          if (state is AssessmentLoaded) {
            _populateFields(state.assessment);
          } else if (state is AssessmentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            context.pop(); // Kembali ke halaman edit kuis
          } else if (state is AssessmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: theme.colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is AssessmentLoading && !_isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AssessmentInitial) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: SharedCard(
                  borderRadius: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 64, color: AppColors.accentLight),
                      const SizedBox(height: 16),
                      Text(
                        'Kuis Belum Terdaftar',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimaryLight),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Harap generate kuis aljabar/soal terlebih dahulu di halaman edit sebelum melakukan pengaturan jadwal.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        child: Text('Kembali', style: GoogleFonts.outfit()),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pengaturan Akses Kuis',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Atur jadwal pengerjaan kuis pintar siswa serta status publikasinya.',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 32),

                  // 1. Start Date Time Input
                  SharedInput(
                    controller: _startDateController,
                    readOnly: true,
                    labelText: 'Waktu Pembukaan Kuis',
                    prefixIcon: Icons.date_range_rounded,
                    hintText: 'Pilih Tanggal & Jam',
                    onTap: () => _pickDateTime(true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Waktu pembukaan wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. End Date Time Input
                  SharedInput(
                    controller: _endDateController,
                    readOnly: true,
                    labelText: 'Tenggat Waktu Penutupan Kuis',
                    prefixIcon: Icons.event_busy_rounded,
                    hintText: 'Pilih Tanggal & Jam',
                    onTap: () => _pickDateTime(false),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tenggat waktu wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3. Duration Input
                  SharedInput(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    labelText: 'Durasi Pengerjaan (Menit)',
                    prefixIcon: Icons.timer_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Durasi pengerjaan wajib diisi';
                      }
                      final dur = int.tryParse(value);
                      if (dur == null || dur <= 0) {
                        return 'Durasi harus berupa angka bulat positif';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 4. Publish Toggle Switch
                  SharedCard(
                    borderRadius: 14,
                    padding: EdgeInsets.zero,
                    child: SwitchListTile(
                      title: Text('Publikasikan Kuis', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      subtitle: Text('Jika aktif, siswa kelas dapat melihat dan mengerjakan kuis ini.', style: GoogleFonts.outfit(fontSize: 12)),
                      activeColor: AppColors.primaryLight,
                      value: _isPublished,
                      onChanged: (val) {
                        setState(() {
                          _isPublished = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  SharedButton(
                    onPressed: _onSave,
                    text: 'Simpan Pengaturan Kuis',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
