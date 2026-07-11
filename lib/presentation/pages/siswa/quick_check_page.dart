import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/material_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/quick_check/quick_check_bloc.dart';
import '../../bloc/quick_check/quick_check_event.dart';
import '../../bloc/quick_check/quick_check_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/shared_ui_kit.dart';

// Catatan: Pastikan package 'lottie' sudah ditambahkan di pubspec.yaml
// import 'package:lottie/lottie.dart';

class QuickCheckPage extends StatefulWidget {
  final MaterialModel material;
  final String assessmentType; // 'quick_check' or 'quiz_utama'

  const QuickCheckPage({
    super.key,
    required this.material,
    this.assessmentType = 'quick_check',
  });

  @override
  State<QuickCheckPage> createState() => _QuickCheckPageState();
}

class _QuickCheckPageState extends State<QuickCheckPage> {
  final Map<String, dynamic> _selectedAnswers = {};
  Timer? _countdownTimer;
  Duration _remainingCooldown = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadQuickCheck();
  }

  void _loadQuickCheck() {
    final authState = context.read<AuthBloc>().state;
    String studentId = 'dummy_student';
    if (authState is Authenticated) {
      studentId = authState.user.uid;
    }
    context.read<QuickCheckBloc>().add(
      LoadQuickCheck(
        materialId: widget.material.materialId,
        studentId: studentId,
        assessmentType: widget.assessmentType,
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer(DateTime cooldownUntil) {
    _countdownTimer?.cancel();
    _updateRemainingCooldown(cooldownUntil);

    if (_remainingCooldown.inSeconds > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateRemainingCooldown(cooldownUntil);
        if (_remainingCooldown.inSeconds <= 0) {
          timer.cancel();
          _loadQuickCheck(); // Reload kuis jika waktu habis
        }
      });
    }
  }

  void _updateRemainingCooldown(DateTime cooldownUntil) {
    setState(() {
      final now = DateTime.now();
      if (cooldownUntil.isAfter(now)) {
        _remainingCooldown = cooldownUntil.difference(now);
      } else {
        _remainingCooldown = Duration.zero;
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _submitAnswers() {
    context.read<QuickCheckBloc>().add(
          SubmitQuickCheck(answers: _selectedAnswers),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: SharedAppBar(
        title: widget.assessmentType == 'quiz_utama'
            ? 'Kuis Utama: ${widget.material.title}'
            : 'Quick Check: ${widget.material.title}',
      ),
      body: BlocConsumer<QuickCheckBloc, QuickCheckState>(
        listener: (context, state) {
          if (state is QuickCheckFailed || state is QuickCheckCooldown) {
            final cooldownUntil = state is QuickCheckFailed
                ? state.cooldownUntil
                : (state as QuickCheckCooldown).cooldownUntil;
            _startCooldownTimer(cooldownUntil);
          }
        },
        builder: (context, state) {
          if (state is QuickCheckLoading || state is QuickCheckInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is QuickCheckError) {
            return Center(
              child: Text(
                state.message,
                style: GoogleFonts.outfit(color: Colors.red),
              ),
            );
          }

          if (state is QuickCheckCooldown || state is QuickCheckFailed) {
            return _buildCooldownView();
          }

          if (state is QuickCheckPassed) {
            return _buildSuccessView();
          }

          if (state is QuickCheckReady) {
            for (var q in state.questions) {
              if (!_selectedAnswers.containsKey(q.questionId)) {
                if (q.type == 'majemuk_kompleks') {
                  _selectedAnswers[q.questionId] = [1, 1, 1];
                } else if (q.type == 'isian_singkat') {
                  _selectedAnswers[q.questionId] = '';
                }
              }
            }
            return _buildQuizView(state);
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildQuizView(QuickCheckReady state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          color: AppColors.primaryLight.withValues(alpha: 0.1),
          child: Text(
            'Jawab 3 pertanyaan berikut untuk memverifikasi pemahaman Anda.\nMinimal Benar: 2',
            style: GoogleFonts.outfit(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.questions.length,
            itemBuilder: (context, index) {
              final q = state.questions[index];
              return SharedCard(
                borderRadius: 16,
                color: Colors.white,
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.15), width: 1.5),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${q.questionText}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (q.type == 'majemuk_kompleks') ...[
                        ...List.generate(q.options.length, (stmtIndex) {
                          final List<int> currentAnswers = (_selectedAnswers[q.questionId] is List<int>)
                              ? (_selectedAnswers[q.questionId] as List<int>)
                              : [1, 1, 1];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                    'Pernyataan #${stmtIndex + 1}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  q.options[stmtIndex],
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            final newList = List<int>.from(currentAnswers);
                                            newList[stmtIndex] = 1;
                                            _selectedAnswers[q.questionId] = newList;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: currentAnswers[stmtIndex] == 1
                                                ? AppColors.primaryLight
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: currentAnswers[stmtIndex] == 1
                                                  ? AppColors.primaryLight
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Benar (Ya)',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: currentAnswers[stmtIndex] == 1
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            final newList = List<int>.from(currentAnswers);
                                            newList[stmtIndex] = 0;
                                            _selectedAnswers[q.questionId] = newList;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: currentAnswers[stmtIndex] == 0
                                                ? AppColors.error
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: currentAnswers[stmtIndex] == 0
                                                  ? AppColors.error
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Salah (Tidak)',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: currentAnswers[stmtIndex] == 0
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ] else if (q.type == 'isian_singkat') ...[
                        TextFormField(
                          key: ValueKey('student_is_${q.questionId}'),
                          style: GoogleFonts.outfit(color: AppColors.textPrimaryLight, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Tulis jawaban Anda di sini...',
                            hintStyle: GoogleFonts.outfit(color: AppColors.textSecondaryLight.withOpacity(0.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primaryLight),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _selectedAnswers[q.questionId] = val;
                            });
                          },
                        ),
                      ] else ...[
                        ...List.generate(q.options.length, (optIndex) {
                          return RadioListTile<int>(
                            title: Text(
                              q.options[optIndex],
                              style: GoogleFonts.outfit(
                                color: AppColors.textPrimaryLight,
                                fontSize: 14,
                              ),
                            ),
                            value: optIndex,
                            groupValue: _selectedAnswers[q.questionId] is int 
                                ? (_selectedAnswers[q.questionId] as int) 
                                : null,
                            onChanged: (val) {
                              setState(() {
                                if (val != null) {
                                  _selectedAnswers[q.questionId] = val;
                                }
                              });
                            },
                            activeColor: AppColors.primaryLight,
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                      ]
                    ],
                  ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SafeArea(
            child: SharedButton(
              onPressed: _selectedAnswers.length == state.questions.length
                  ? _submitAnswers
                  : () {},
              text: 'Kirim Jawaban',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCooldownView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Jika Lottie belum terinstall, kita gunakan Icon sebagai fallback
            // Lottie.asset('assets/animations/sad.json', height: 150),
            Icon(
              Icons.sentiment_dissatisfied_rounded,
              size: 100,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 24),
            Text(
              'Yah, Sepertinya Kamu Belum Paham',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Skor kamu belum mencapai minimal (Benar 2). Silakan baca dan pelajari modulnya kembali. Kuis akan terbuka dalam:',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.accentLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentLight.withValues(alpha: 0.2)),
              ),
              child: Text(
                _formatDuration(_remainingCooldown),
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentLight,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(), // Kembali ke halaman materi
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(
                  'Kembali Membaca Materi',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade50,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Luar Biasa!',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.assessmentType == 'quiz_utama'
              ? 'Kamu telah menyelesaikan Kuis Utama dan mendapatkan +500 XP! Lencana Master telah terbuka!'
              : 'Kamu telah membuktikan pemahamanmu pada materi ini. Akses menuju Kuis Utama telah dibuka!',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SharedButton(
              onPressed: () {
                if (widget.assessmentType == 'quick_check') {
                  // Navigate to Main Quiz
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => QuickCheckBloc(),
                        child: QuickCheckPage(
                          material: widget.material,
                          assessmentType: 'quiz_utama',
                        ),
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).pop(); // Kembali ke dashboard
                }
              },
              text: widget.assessmentType == 'quiz_utama' ? 'Kembali ke Dashboard' : 'Mulai Kuis Utama',
            ),
          ],
        ),
      ),
    );
  }
}
