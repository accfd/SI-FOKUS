import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/material_model.dart';
import '../../../data/models/question_model.dart';
import '../../../domain/repositories/material_repository.dart';
import '../../bloc/assessment/assessment_bloc.dart';
import '../../bloc/assessment/assessment_event.dart';
import '../../bloc/assessment/assessment_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/shared_ui_kit.dart';

class EditAssessmentPage extends StatefulWidget {
  final String classId;
  final String materialId;
  final String type; // 'quick_check' | 'quiz_utama'

  const EditAssessmentPage({
    super.key,
    required this.classId,
    required this.materialId,
    required this.type,
  });

  @override
  State<EditAssessmentPage> createState() => _EditAssessmentPageState();
}

class _EditAssessmentPageState extends State<EditAssessmentPage> {
  MaterialModel? _material;
  List<QuestionModel> _localQuestions = [];
  String? _assessmentId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadMaterialAndAssessment();
  }

  Future<void> _loadMaterialAndAssessment() async {
    try {
      final materialRepo = context.read<MaterialRepository>();
      final materialStream = materialRepo.streamMaterialDetail(widget.materialId);
      final materialItem = await materialStream.first;
      setState(() {
        _material = materialItem;
      });

      if (mounted) {
        context.read<AssessmentBloc>().add(
              FetchAssessmentByMaterial(
                materialId: widget.materialId,
                type: widget.type,
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat materi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onGenerateQuiz() {
    if (_material == null) return;
    context.read<AssessmentBloc>().add(
          GenerateAssessmentRequested(
            materialId: widget.materialId,
            classId: widget.classId,
            type: widget.type,
            materialTitle: _material!.title,
            fileUrl: _material!.fileUrl,
          ),
        );
  }

  void _addQuestion() {
    setState(() {
      _localQuestions.add(
        QuestionModel(
          questionId: 'q_manual_${DateTime.now().millisecondsSinceEpoch}',
          questionText: 'Tulis soal pertanyaan baru di sini...',
          options: ['', '', '', '', ''],
          correctAnswerIndex: 0,
          type: 'pilihan_ganda',
        ),
      );
    });
  }

  void _deleteQuestion(int index) {
    setState(() {
      _localQuestions.removeAt(index);
    });
  }

  void _onSaveAssessment() {
    if (_assessmentId == null) return;

    // Validasi input
    for (int i = 0; i < _localQuestions.length; i++) {
      final q = _localQuestions[i];
      if (q.questionText.trim().isEmpty) {
        _showErrorSnackBar('Pertanyaan ke-${i + 1} tidak boleh kosong.');
        return;
      }
      for (int j = 0; j < q.options.length; j++) {
        if (q.options[j].trim().isEmpty) {
          _showErrorSnackBar('Opsi ke-${j + 1} pada Pertanyaan ke-${i + 1} tidak boleh kosong.');
          return;
        }
      }
    }

    context.read<AssessmentBloc>().add(
          UpdateAssessmentQuestions(
            assessmentId: _assessmentId!,
            questions: _localQuestions,
            materialId: widget.materialId,
            type: widget.type,
          ),
        );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleLabel = widget.type == 'quick_check' ? 'AI Quick Check (3 Soal)' : 'AI Kuis Utama (10 Soal)';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: SharedAppBar(
        title: titleLabel,
        actions: [
          if (_isInitialized)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Atur Jadwal & Publikasi',
              onPressed: () {
                context.push('/dashboard/guru/class/${widget.classId}/material/${widget.materialId}/assessment/${widget.type}/config');
              },
            ),
        ],
      ),
      body: BlocConsumer<AssessmentBloc, AssessmentState>(
        listener: (context, state) {
          if (state is AssessmentLoaded) {
            if (!_isInitialized) {
              setState(() {
                _localQuestions = List<QuestionModel>.from(state.assessment.questions);
                _assessmentId = state.assessment.assessmentId;
                _isInitialized = true;
              });
            }
          } else if (state is AssessmentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            context.pop(); // Kembali ke upload
          } else if (state is AssessmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: theme.colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (_material == null || (state is AssessmentLoading && !_isInitialized)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    state is AssessmentLoading 
                        ? 'Gemini AI sedang menyusun soal asesmen...' 
                        : 'Memuat data materi...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          if (state is AssessmentInitial) {
            // GENERATE BUTTON SCREEN
            return _buildGenerateIntroScreen(theme);
          }

          // Kuis loaded & sedang diedit
          return _buildEditorScreen(theme);
        },
      ),
    );
  }

  Widget _buildGenerateIntroScreen(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SharedCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 32,
              color: AppColors.primaryLight.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.12), width: 1.5),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 64,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hasilkan Soal dengan AI',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada soal asesmen untuk materi "${_material!.title}". Klik tombol di bawah untuk meminta Gemini AI menganalisis isi modul dan menghasilkan kuis pilihan ganda secara otomatis.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 32),
            SharedButton(
              onPressed: _onGenerateQuiz,
              icon: Icons.auto_awesome_rounded,
              text: widget.type == 'quick_check' ? 'Hasilkan 3 Soal Quick Check' : 'Hasilkan 10 Soal Kuis Utama',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorScreen(ThemeData theme) {
    return Column(
      children: [
        // Top Info Bar
        SharedCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 12,
          color: AppColors.primaryLight.withValues(alpha: 0.05),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.1)),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Silakan tinjau kuis di bawah. Anda dapat menyunting soal, opsi, dan kunci jawaban sebelum menyimpan.',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),
        
        // Questions List Form
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _localQuestions.length,
            itemBuilder: (context, index) {
              final q = _localQuestions[index];
              return _buildQuestionEditCard(theme, q, index);
            },
          ),
        ),

        // Action Bottom Panel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_rounded),
                  label: Text('Tambah Soal', style: GoogleFonts.outfit()),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SharedButton(
                  onPressed: _onSaveAssessment,
                  icon: Icons.check_rounded,
                  text: 'Simpan Asesmen',
                  backgroundColor: AppColors.primaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  QuestionModel _generateNewRandomQuestion(String title, int index, String currentType) {
    final random = Random();
    final keywords = title.split(' ').where((w) => w.length > 3).toList();
    final keyword = keywords.isNotEmpty ? keywords[random.nextInt(keywords.length)] : 'Topik Utama';

    if (currentType == 'majemuk_kompleks') {
      return QuestionModel(
        questionId: 'q_gen_${DateTime.now().millisecondsSinceEpoch}_$index',
        questionText: 'Tentukan kebenaran dari pernyataan berikut mengenai $keyword dalam materi $title:',
        options: [
          'Konsep $keyword berperan penting dalam meningkatkan pemahaman.',
          'Penerapan $keyword tidak memiliki pengaruh pada hasil kuis.',
          'Evaluasi $keyword dilakukan secara berkala dan sistematis.'
        ],
        correctAnswerIndex: 0,
        type: 'majemuk_kompleks',
        correctAnswers: const [1, 0, 1], // Benar, Salah, Benar
      );
    } else if (currentType == 'isian_singkat') {
      return QuestionModel(
        questionId: 'q_gen_${DateTime.now().millisecondsSinceEpoch}_$index',
        questionText: 'Proses utama yang dibahas pada topik $title yang berkaitan dengan $keyword disebut...',
        options: const [],
        correctAnswerIndex: 0,
        type: 'isian_singkat',
        correctAnswerText: keyword.toLowerCase(),
      );
    } else {
      // Pilihan Ganda (5 Opsi)
      return QuestionModel(
        questionId: 'q_gen_${DateTime.now().millisecondsSinceEpoch}_$index',
        questionText: 'Manakah dari pernyataan berikut yang paling tepat menggambarkan dampak konsep $keyword dalam pembahasan $title?',
        options: [
          'Meningkatkan efisiensi pemecahan masalah secara terukur',
          'Mengurangi alur pemikiran yang tidak logis',
          'Hanya sebagai pelengkap materi pembelajaran dasar',
          'Membatasi kreativitas berfikir dalam mencari solusi',
          'Mempercepat durasi penyelesaian modul'
        ],
        correctAnswerIndex: 0,
        type: 'pilihan_ganda',
      );
    }
  }

  Future<void> _regenerateQuestionWithAI(int index, QuestionModel q) async {
    if (_material == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Gemini AI sedang menyusun soal baru...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/generate-single-question'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'file_url': _material!.fileUrl,
          'question_type': q.type,
        }),
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        Navigator.of(context).pop(); // Tutup loading dialog
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _localQuestions[index] = QuestionModel(
            questionId: 'q_gen_${DateTime.now().millisecondsSinceEpoch}_$index',
            questionText: data['questionText'] ?? 'Pertanyaan baru...',
            options: (data['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
            correctAnswerIndex: data['correctAnswerIndex'] as int? ?? 0,
            type: q.type,
            correctAnswers: (data['correctAnswers'] as List<dynamic>?)?.map((e) => e as int).toList(),
            correctAnswerText: data['correctAnswerText'] as String?,
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Soal berhasil diperbarui secara langsung dari dokumen via Gemini AI!')),
          );
        }
      } else {
        _useLocalFallback(index, q.type);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Tutup loading dialog
      }
      _useLocalFallback(index, q.type);
    }
  }

  void _useLocalFallback(int index, String type) {
    setState(() {
      _localQuestions[index] = _generateNewRandomQuestion(
        _material?.title ?? 'Modul',
        index,
        type,
      );
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koneksi backend terputus. Soal diperbarui menggunakan AI Fallback lokal.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildQuestionEditCard(ThemeData theme, QuestionModel q, int index) {
    // Pad options as necessary
    List<String> options = List<String>.from(q.options);
    if (q.type == 'pilihan_ganda') {
      while (options.length < 5) {
        options.add('');
      }
    } else if (q.type == 'majemuk_kompleks') {
      while (options.length < 3) {
        options.add('');
      }
    }

    return SharedCard(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Soal ${index + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryLight),
                      tooltip: 'Segarkan Soal (AI)',
                      onPressed: () => _regenerateQuestionWithAI(index, q),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                      onPressed: () => _deleteQuestion(index),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dropdown Tipe Soal
            DropdownButtonFormField<String>(
              value: q.type,
              decoration: const InputDecoration(
                labelText: 'Model Tipe Soal (UTBK SNBT)',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'pilihan_ganda', child: Text('Pilihan Ganda Biasa (5 Opsi)')),
                DropdownMenuItem(value: 'majemuk_kompleks', child: Text('Pilihan Majemuk Kompleks (Tabel True/False)')),
                DropdownMenuItem(value: 'isian_singkat', child: Text('Isian Singkat (Rumpang)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    List<String> newOpts = [];
                    List<int>? newAnswers;
                    String? newAnswerText;

                    if (val == 'pilihan_ganda') {
                      newOpts = ['', '', '', '', ''];
                    } else if (val == 'majemuk_kompleks') {
                      newOpts = ['Pernyataan A', 'Pernyataan B', 'Pernyataan C'];
                      newAnswers = [1, 0, 1]; // Default True, False, True
                    } else if (val == 'isian_singkat') {
                      newAnswerText = '';
                    }

                    _localQuestions[index] = q.copyWith(
                      type: val,
                      options: newOpts,
                      correctAnswers: newAnswers,
                      correctAnswerText: newAnswerText,
                    );
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Question Text Input
            TextFormField(
              initialValue: q.questionText,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Pertanyaan',
                alignLabelWithHint: true,
              ),
              onChanged: (val) {
                _localQuestions[index] = q.copyWith(questionText: val);
              },
            ),
            const SizedBox(height: 16),

            // Render Editor berdasarkan type
            if (q.type == 'pilihan_ganda') ...[
              const Text('Pilihan Ganda (5 Opsi) & Kunci Jawaban:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              Column(
                children: List.generate(5, (optIndex) {
                  final optionLabel = String.fromCharCode(65 + optIndex); // A, B, C, D, E
                  final isCorrect = q.correctAnswerIndex == optIndex;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: optIndex,
                          groupValue: q.correctAnswerIndex,
                          activeColor: theme.colorScheme.secondary,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _localQuestions[index] = q.copyWith(correctAnswerIndex: val);
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('pg_${q.questionId}_$optIndex'),
                            initialValue: options[optIndex],
                            decoration: InputDecoration(
                              labelText: 'Opsi $optionLabel',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: isCorrect
                                  ? theme.colorScheme.secondary.withValues(alpha: 0.08)
                                  : theme.cardColor,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isCorrect ? theme.colorScheme.secondary : Colors.grey.shade300,
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              options[optIndex] = val;
                              _localQuestions[index] = q.copyWith(options: options);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ] else if (q.type == 'majemuk_kompleks') ...[
              const Text('Tabel Kebenaran Pernyataan (Kompleks):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              Column(
                children: List.generate(3, (stmtIndex) {
                  final answers = q.correctAnswers ?? [1, 0, 1];
                  final currentVal = answers.length > stmtIndex ? answers[stmtIndex] : 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: ValueKey('mk_stmt_${q.questionId}_$stmtIndex'),
                            initialValue: options[stmtIndex],
                            decoration: InputDecoration(
                              labelText: 'Pernyataan #${stmtIndex + 1}',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            onChanged: (val) {
                              options[stmtIndex] = val;
                              _localQuestions[index] = q.copyWith(options: options);
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text('Kunci Jawaban:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    final newAnswers = List<int>.from(answers);
                                    newAnswers[stmtIndex] = 1;
                                    _localQuestions[index] = q.copyWith(correctAnswers: newAnswers);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: currentVal == 1 ? Colors.green.shade50 : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: currentVal == 1 ? Colors.green : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    'Benar (Ya)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: currentVal == 1 ? Colors.green.shade700 : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    final newAnswers = List<int>.from(answers);
                                    newAnswers[stmtIndex] = 0;
                                    _localQuestions[index] = q.copyWith(correctAnswers: newAnswers);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: currentVal == 0 ? Colors.red.shade50 : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: currentVal == 0 ? Colors.red : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    'Salah (Tidak)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: currentVal == 0 ? Colors.red.shade700 : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ] else if (q.type == 'isian_singkat') ...[
              const Text('Kunci Jawaban Isian Singkat:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              TextFormField(
                key: ValueKey('is_${q.questionId}'),
                initialValue: q.correctAnswerText ?? '',
                decoration: const InputDecoration(
                  labelText: 'Jawaban Benar (Case-insensitive)',
                  hintText: 'Tulis kata kunci jawaban...',
                ),
                onChanged: (val) {
                  _localQuestions[index] = q.copyWith(correctAnswerText: val);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
