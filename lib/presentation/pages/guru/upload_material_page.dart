import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/material_model.dart';
import '../../../domain/repositories/material_repository.dart';
import '../../bloc/material/material_bloc.dart';
import '../../bloc/material/material_event.dart';
import '../../bloc/material/material_state.dart';

class UploadMaterialPage extends StatefulWidget {
  final String classId;

  const UploadMaterialPage({
    super.key,
    required this.classId,
  });

  @override
  State<UploadMaterialPage> createState() => _UploadMaterialPageState();
}

class _UploadMaterialPageState extends State<UploadMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  PlatformFile? _selectedFile;
  String? _uploadedMaterialId;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'pptx'],
        withData: true, // Need data bytes for firebase upload
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          // Pre-fill title with file name without extension
          final name = _selectedFile!.name;
          final lastDot = name.lastIndexOf('.');
          _titleController.text = lastDot != -1 ? name.substring(0, lastDot) : name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih berkas: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _onUpload() {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih berkas dokumen terlebih dahulu.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final extension = _selectedFile!.extension?.toLowerCase() ?? 'pdf';
      final fileBytes = _selectedFile!.bytes;

      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat isi berkas.'), backgroundColor: Colors.red),
        );
        return;
      }

      context.read<MaterialBloc>().add(
            UploadMaterial(
              classId: widget.classId,
              title: _titleController.text.trim(),
              fileName: _selectedFile!.name,
              fileBytes: fileBytes,
              fileType: extension == 'docx'
                  ? 'docx'
                  : extension == 'pptx'
                      ? 'pptx'
                      : 'pdf',
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Materi Pintar'),
      ),
      body: BlocConsumer<MaterialBloc, MaterialBlocState>(
        listener: (context, state) {
          if (state is MaterialUploadSuccess) {
            setState(() {
              _uploadedMaterialId = state.material.materialId;
              _isPublishing = state.material.isPublished;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Materi berhasil diunggah! AI sedang memproses ringkasan...'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is MaterialError) {
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_uploadedMaterialId == null) ...[
                  // 1. UPLOAD FORM STATE
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Pilih Dokumen Pembelajaran',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload berkas PDF, Word (DOCX), atau PowerPoint (PPTX). AI akan secara otomatis memproses isi dokumen untuk menghasilkan ringkasan pembelajaran.',
                          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        
                        // Picker Area
                        _buildFilePickerArea(theme),
                        const SizedBox(height: 24),
                        
                        // Title Input
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Judul Materi',
                            prefixIcon: Icon(Icons.title_rounded),
                            hintText: 'Misal: Bab 1 Aljabar Linear',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Judul materi tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Upload Progress or Trigger Button
                        if (state is MaterialUploadProgress) ...[
                          _buildUploadProgressIndicator(theme, state.progress),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: _selectedFile == null ? null : _onUpload,
                            icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                            label: const Text('Mulai Unggah Materi'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  // 2. SUMMARY PREVIEW & AI PROCESSING STATE
                  _buildAiProcessingSection(theme),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilePickerArea(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
          child: Column(
            children: [
              if (_selectedFile == null) ...[
                Icon(Icons.insert_drive_file_outlined, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                const Text(
                  'Ketuk untuk memilih berkas dokumen',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mendukung PDF, DOCX, PPTX (Maks 10MB)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ] else ...[
                Icon(
                  _selectedFile!.extension?.toLowerCase() == 'pdf'
                      ? Icons.picture_as_pdf_rounded
                      : _selectedFile!.extension?.toLowerCase() == 'pptx'
                          ? Icons.slideshow_rounded
                          : Icons.description_rounded,
                  size: 64,
                  color: Colors.red.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedFile!.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ukuran Berkas: ${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Ganti Berkas'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgressIndicator(ThemeData theme, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mengunggah dokumen...', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            borderRadius: BorderRadius.circular(6),
            minHeight: 8,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildAiProcessingSection(ThemeData theme) {
    final materialRepository = context.read<MaterialRepository>();

    return StreamBuilder<MaterialModel>(
      stream: materialRepository.streamMaterialDetail(_uploadedMaterialId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Gagal sinkronisasi metadata: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final material = snapshot.data!;
        final hasSummary = material.summary != null && material.summary!.trim().isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              elevation: 0,
              color: hasSummary
                  ? theme.colorScheme.secondary.withValues(alpha: 0.08)
                  : theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: hasSummary
                      ? theme.colorScheme.secondary.withValues(alpha: 0.2)
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      hasSummary ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                      color: hasSummary ? theme.colorScheme.secondary : theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasSummary ? 'Analisis Dokumen Selesai' : 'Sedang Memproses Dokumen',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasSummary
                                ? 'Gemini AI telah berhasil menganalisis dan meringkas dokumen Anda.'
                                : 'Gemini AI sedang membaca dan menyusun ringkasan serta Quick Check.',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Document Details
            Text(
              material.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Tipe Dokumen: ${material.fileType.toUpperCase()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Summary View
            if (!hasSummary) ...[
              // LOADING SUMMARY STATE
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Memproses dokumen dengan AI...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ini memakan waktu sekitar 10 - 20 detik.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // SUMMARY LOADED CARD
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.summarize_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Ringkasan Materi AI',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        material.summary!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // AI Assessment Options (F-03)
            if (hasSummary) ...[
              Text(
                'AI Assessment Generator',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () {
                        context.push('/dashboard/guru/class/${widget.classId}/material/${material.materialId}/assessment/quick_check');
                      },
                      icon: const Icon(Icons.flash_on_rounded),
                      label: const Text('Quick Check', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.tertiary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () {
                        context.push('/dashboard/guru/class/${widget.classId}/material/${material.materialId}/assessment/quiz_utama');
                      },
                      icon: const Icon(Icons.assignment_rounded),
                      label: const Text('Kuis Utama', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  context.push('/dashboard/guru/class/${widget.classId}/material/${material.materialId}/intervention');
                },
                icon: const Icon(Icons.lightbulb_rounded),
                label: const Text('Lihat Rekomendasi Intervensi Belajar AI'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: HSLColor.fromAHSL(1.0, 165, 0.80, 0.38).toColor(),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  context.push('/dashboard/guru/class/${widget.classId}/material/${material.materialId}/resources');
                },
                icon: const Icon(Icons.library_books_rounded),
                label: const Text('Kelola Sumber Belajar Tambahan'),
              ),
              const SizedBox(height: 24),
            ],

            // Publish Toggle Switch
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                title: const Text('Publikasikan ke Siswa', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Jika aktif, siswa dapat mengakses modul ini di dasbor mereka.'),
                value: _isPublishing,
                onChanged: (value) {
                  setState(() {
                    _isPublishing = value;
                  });
                  context.read<MaterialBloc>().add(
                        UpdateMaterialPublishStatus(
                          materialId: material.materialId,
                          isPublished: value,
                          classId: widget.classId,
                        ),
                      );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Back button
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali ke Rincian Kelas'),
            ),
          ],
        );
      },
    );
  }
}
