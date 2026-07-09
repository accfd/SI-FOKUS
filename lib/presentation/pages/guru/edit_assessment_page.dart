import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/material_model.dart';
import '../../../data/models/question_model.dart';
import '../../../domain/repositories/material_repository.dart';
import '../../bloc/assessment/assessment_bloc.dart';
import '../../bloc/assessment/assessment_event.dart';
import '../../bloc/assessment/assessment_state.dart';

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
          options: ['', '', '', ''],
          correctAnswerIndex: 0,
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
      appBar: AppBar(
        title: Text(titleLabel),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 64,
                color: theme.colorScheme.primary,
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
            ElevatedButton.icon(
              onPressed: _onGenerateQuiz,
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              label: Text(widget.type == 'quick_check' ? 'Hasilkan 3 Soal Quick Check' : 'Hasilkan 10 Soal Kuis Utama'),
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
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Silakan tinjau kuis di bawah. Anda dapat menyunting soal, opsi, dan kunci jawaban sebelum menyimpan.',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
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
                  label: const Text('Tambah Soal'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _onSaveAssessment,
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: const Text('Simpan Asesmen'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionEditCard(ThemeData theme, QuestionModel q, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                  onPressed: () => _deleteQuestion(index),
                ),
              ],
            ),
            const SizedBox(height: 12),

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

            // 4 Options Inputs
            const Text('Pilihan Ganda & Kunci Jawaban:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            
            Column(
              children: List.generate(4, (optIndex) {
                final optionLabel = String.fromCharCode(65 + optIndex); // A, B, C, D
                final isCorrect = q.correctAnswerIndex == optIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      // Radio Button for Kunci
                      // ignore: deprecated_member_use
                      Radio<int>(
                        value: optIndex,
                        // ignore: deprecated_member_use
                        groupValue: q.correctAnswerIndex,
                        activeColor: theme.colorScheme.secondary,
                        // ignore: deprecated_member_use
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _localQuestions[index] = q.copyWith(correctAnswerIndex: val);
                            });
                          }
                        },
                      ),
                      
                      // Option Text Field
                      Expanded(
                        child: TextFormField(
                          initialValue: q.options.length > optIndex ? q.options[optIndex] : '',
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
                            final newOptions = List<String>.from(q.options);
                            while (newOptions.length <= optIndex) {
                              newOptions.add('');
                            }
                            newOptions[optIndex] = val;
                            _localQuestions[index] = q.copyWith(options: newOptions);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
