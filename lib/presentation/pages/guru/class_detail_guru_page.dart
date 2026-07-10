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

class ClassDetailGuruPage extends StatelessWidget {
  final String classId;

  const ClassDetailGuruPage({
    super.key,
    required this.classId,
  });

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
                    DeleteClass(classId: classId, teacherId: teacherId),
                  );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
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
        stream: classRepository.streamClassDetail(classId),
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
            appBar: SharedAppBar(
              title: classItem.className,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () => _onDeleteClass(context, classItem.className, classItem.teacherId),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Class Header Info Card
                   _buildHeaderCard(context, classItem),
                  const SizedBox(height: 16),
                  SharedButton(
                    onPressed: () => context.push('/dashboard/guru/class/${classItem.classId}/upload'),
                    icon: Icons.menu_book_rounded,
                    text: 'Kelola & Unggah Materi Pintar',
                    backgroundColor: AppColors.primaryLight,
                  ),
                  const SizedBox(height: 12),
                  SharedButton(
                    onPressed: () => context.push('/dashboard/guru/class/${classItem.classId}/competency'),
                    icon: Icons.analytics_rounded,
                    text: 'Lihat Dasbor Kompetensi Kelas (AI)',
                    backgroundColor: AppColors.secondaryLight,
                  ),
                  const SizedBox(height: 12),
                  SharedButton(
                    onPressed: () => context.push('/dashboard/guru/class/${classItem.classId}/analytics'),
                    icon: Icons.show_chart_rounded,
                    text: 'Lihat Analisis Tren Belajar Kelas',
                    backgroundColor: AppColors.accentLight,
                    foregroundColor: AppColors.textPrimaryLight,
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
                        onPressed: () => context.push('/dashboard/guru/class/${classItem.classId}/upload'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<MaterialModel>>(
                    future: context.read<MaterialRepository>().fetchClassMaterials(classItem.classId),
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
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Icon(Icons.picture_as_pdf_rounded, color: theme.colorScheme.primary),
                              ),
                              title: Text(
                                material.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: material.isPublished ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    material.fileType.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              onTap: () {
                                context.push('/dashboard/guru/class/${classItem.classId}/upload?materialId=${material.materialId}');
                              },
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
                  StreamBuilder<List<UserModel>>(
                    stream: classRepository.streamClassStudents(classItem.studentUids),
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
    final theme = Theme.of(context);

    return SharedCard(
      borderRadius: 20,
      color: AppColors.primaryLight.withValues(alpha: 0.06),
      border: Border.all(
        color: AppColors.primaryLight.withValues(alpha: 0.12),
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
                    const Text(
                      'Kode Masuk Kelas:',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          classItem.classCode,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.grey),
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
    final theme = Theme.of(context);
    return SharedCard(
      padding: EdgeInsets.zero,
      borderRadius: 14,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.12),
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Lvl ${student.level}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${student.xp} XP',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }
}
