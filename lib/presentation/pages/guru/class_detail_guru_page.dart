import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/shared_ui_kit.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/material_model.dart';
import '../../../domain/repositories/class_repository.dart';
import '../../../domain/repositories/material_repository.dart';
import '../../bloc/class/class_bloc.dart';
import '../../bloc/class/class_event.dart';
import '../../bloc/class/class_state.dart';
import '../../bloc/gamification/gamification_bloc.dart';
import '../siswa/leaderboard_page.dart';

class ClassDetailGuruPage extends StatefulWidget {
  final String classId;

  const ClassDetailGuruPage({
    super.key,
    required this.classId,
  });

  @override
  State<ClassDetailGuruPage> createState() => _ClassDetailGuruPageState();
}

class _ClassDetailGuruPageState extends State<ClassDetailGuruPage> {
  late Stream<ClassModel> _classStream;
  late Future<List<MaterialModel>> _materialsFuture;
  
  Stream<List<UserModel>>? _studentsStream;
  List<String>? _lastStudentUids;

  @override
  void initState() {
    super.initState();
    final classRepository = context.read<ClassRepository>();
    final materialRepository = context.read<MaterialRepository>();
    
    _classStream = classRepository.streamClassDetail(widget.classId);
    _materialsFuture = materialRepository.fetchClassMaterials(widget.classId);
  }

  bool _areListsEqual(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _onDeleteClass(BuildContext context, String className, String teacherId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Kelas?'),
        content: Text('Apakah Anda yakin ingin menghapus kelas "$className"? Semua data aktivitas kelas ini akan hilang permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 40),
            ),
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              context.read<ClassBloc>().add(
                    DeleteClass(classId: widget.classId, teacherId: teacherId),
                  );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showClassSettingsBottomSheet(BuildContext context, ClassModel classItem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Pengaturan Kelas',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola pengaturan untuk ${classItem.className}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  ),
                  title: Text(
                    'Hapus Kelas',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  subtitle: Text(
                    'Menghapus kelas dan semua aktivitas di dalamnya',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext); // Close sheet
                    _onDeleteClass(context, classItem.className, classItem.teacherId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classRepository = context.read<ClassRepository>();

    return BlocListener<ClassBloc, ClassState>(
      listener: (context, state) {
        if (state is ClassSuccess && state.message.contains('dihapus')) {
          context.go('/dashboard/guru');
        }
      },
      child: StreamBuilder<ClassModel>(
        stream: _classStream,
        builder: (context, classSnapshot) {
          if (classSnapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error Detail Kelas')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Gagal memuat detail kelas: ${classSnapshot.error}'),
                ),
              ),
            );
          }

          if (classSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final classItem = classSnapshot.data!;

          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              title: Text(
                classItem.className,
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              backgroundColor: AppColors.backgroundLight,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight),
                onPressed: () => context.go('/dashboard/guru'),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: AppColors.textPrimaryLight),
                  onPressed: () => _showClassSettingsBottomSheet(context, classItem),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class Header Info Card
                   _buildHeaderCard(context, classItem),
                  const SizedBox(height: 16),

                  SharedButton(
                    onPressed: () => context.push('/dashboard/guru/class/${classItem.classId}/competency'),
                    icon: Icons.analytics_rounded,
                    text: 'Lihat Dasbor Kompetensi Kelas (AI)',
                    backgroundColor: AppColors.primaryLight,
                  ),
                  const SizedBox(height: 12),
                  SharedButton(
                    onPressed: () => context.push('/dashboard/guru/class/${classItem.classId}/analytics'),
                    icon: Icons.show_chart_rounded,
                    text: 'Lihat Analisis Tren Belajar Kelas',
                    backgroundColor: AppColors.secondaryLight,
                  ),
                  const SizedBox(height: 12),
                  SharedButton(
                    onPressed: () => context.push('/dashboard/guru/class/${classItem.classId}/talent'),
                    icon: Icons.emoji_events_rounded,
                    text: 'Lihat Rekomendasi Bakat Siswa Kelas',
                    backgroundColor: AppColors.accentLight,
                    foregroundColor: AppColors.textPrimaryLight,
                  ),
                  const SizedBox(height: 12),
                  SharedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => GamificationBloc(),
                            child: LeaderboardPage(classId: classItem.classId),
                          ),
                        ),
                      );
                    },
                    icon: Icons.leaderboard_rounded,
                    text: 'Lihat Leaderboard Kelas',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryLight,
                  ),
                  const SizedBox(height: 24),

                  // Materials Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Materi Pintar Kelas',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimaryLight),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.teal),
                        tooltip: 'Unggah Materi Baru',
                        onPressed: () async {
                          await context.push('/dashboard/guru/class/${classItem.classId}/upload');
                          if (mounted) {
                            setState(() {
                              _materialsFuture = context.read<MaterialRepository>().fetchClassMaterials(widget.classId);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<MaterialModel>>(
                    future: _materialsFuture,
                    builder: (context, materialsSnapshot) {
                      if (materialsSnapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('Gagal memuat materi: ${materialsSnapshot.error}'),
                        );
                      }
                      if (materialsSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final materials = materialsSnapshot.data ?? [];
                      if (materials.isEmpty) {
                         return const SharedCard(
                          borderRadius: 14,
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'Belum ada materi pintar yang diunggah.\nKetuk tombol tambah (+) atau tombol Kelola di atas untuk mengunggah materi pertama.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: materials.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final material = materials[index];
                          return SharedCard(
                            padding: EdgeInsets.zero,
                            borderRadius: 14,
                            color: Colors.white,
                            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.15), width: 1.5),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.08),
                                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryLight),
                                ),
                                title: Text(
                                  material.title,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: material.isPublished
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        material.isPublished ? 'Dipublikasikan' : 'Draft',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: material.isPublished ? Colors.green.shade800 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      material.fileType.toUpperCase(),
                                      style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondaryLight),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
                                onTap: () async {
                                  await context.push('/dashboard/guru/class/${classItem.classId}/upload?materialId=${material.materialId}');
                                  if (mounted) {
                                    setState(() {
                                      _materialsFuture = context.read<MaterialRepository>().fetchClassMaterials(widget.classId);
                                    });
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Student List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Siswa Terdaftar',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimaryLight),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${classItem.studentUids.length} Siswa',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Real-time Students List
                  (() {
                    if (_studentsStream == null || !_areListsEqual(_lastStudentUids, classItem.studentUids)) {
                      _lastStudentUids = classItem.studentUids;
                      _studentsStream = classRepository.streamClassStudents(classItem.studentUids);
                    }
                    return const SizedBox.shrink();
                  })(),
                  StreamBuilder<List<UserModel>>(
                    stream: _studentsStream,
                    builder: (context, studentsSnapshot) {
                      if (studentsSnapshot.hasError) {
                        return Center(child: Text('Gagal memuat data siswa: ${studentsSnapshot.error}'));
                      }

                      if (studentsSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final students = studentsSnapshot.data ?? [];

                      if (students.isEmpty) {
                        return const SharedCard(
                          borderRadius: 14,
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  'Belum Ada Siswa',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Bagikan kode akses di atas kepada siswa Anda untuk bergabung ke kelas ini.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: students.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _buildStudentTile(context, student);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ClassModel classItem) {
    return SharedCard(
      borderRadius: 20,
      color: Colors.white,
      border: Border.all(
        color: AppColors.primaryLight.withValues(alpha: 0.15),
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            classItem.subjectName.toUpperCase(),
            style: GoogleFonts.outfit(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            classItem.className,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kode Masuk Kelas:',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        classItem.classCode,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondaryLight),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: classItem.classCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kode kelas berhasil disalin!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 36, color: AppColors.primaryLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(BuildContext context, UserModel student) {
    return SharedCard(
      padding: EdgeInsets.zero,
      borderRadius: 14,
      color: Colors.white,
      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.15), width: 1.5),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.08),
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            student.name,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimaryLight,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.email,
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Lvl ${student.level}',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${student.xp} XP',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
        ),
      ),
    );
  }
}
