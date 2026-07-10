import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/material_model.dart';
import '../../../data/models/student_progress_model.dart';
import '../../../data/models/learning_resource_model.dart';
import '../../../data/repositories/mock_db.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/quick_check/quick_check_bloc.dart';
import 'pdf_viewer_page.dart';
import 'quick_check_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/shared_ui_kit.dart';

bool get isMockMode {
  try {
    return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
  } catch (_) {
    return true;
  }
}

class SiswaClassDetailPage extends StatelessWidget {
  final ClassModel classItem;

  const SiswaClassDetailPage({super.key, required this.classItem});

  Future<List<MaterialModel>> _fetchClassMaterials() async {
    if (isMockMode) {
      final allMaterials = await MockDb.getAll('materials');
      return allMaterials
          .where((m) => m['classId'] == classItem.classId && m['isPublished'] == true)
          .map((m) => MaterialModel.fromJson(m))
          .toList();
    }

    final query = await FirebaseFirestore.instance
        .collection('materials')
        .where('classId', isEqualTo: classItem.classId)
        .where('isPublished', isEqualTo: true)
        .get();
    return query.docs.map((doc) => MaterialModel.fromJson(doc.data())).toList();
  }

  Future<StudentProgressModel?> _fetchStudentProgress(String studentUid, String materialId) async {
    if (isMockMode) {
      final allProgress = await MockDb.getAll('student_progress');
      final match = allProgress.firstWhere(
        (p) => p['studentId'] == studentUid && p['materialId'] == materialId,
        orElse: () => const {},
      );
      if (match.isEmpty) return null;
      return StudentProgressModel.fromJson(match);
    }

    final query = await FirebaseFirestore.instance
        .collection('student_progress')
        .where('studentId', isEqualTo: studentUid)
        .where('materialId', isEqualTo: materialId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return StudentProgressModel.fromJson(query.docs.first.data());
  }

  Future<List<LearningResourceModel>> _fetchResources(String materialId) async {
    if (isMockMode) {
      await MockDb.init();
      final raw = await MockDb.getString('learning_resources_$materialId');
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map((e) => LearningResourceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final doc = await FirebaseFirestore.instance.collection('materials').doc(materialId).get();
    if (!doc.exists) return [];
    final data = doc.data()!;
    final rawList = data['learningResources'] as List<dynamic>? ?? [];
    return rawList
        .map((e) => LearningResourceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      // Direct opening fallback if check throws
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final studentUid = authState is Authenticated ? authState.user.uid : 'dummy_student';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: SharedAppBar(
        title: classItem.className,
      ),
      body: FutureBuilder<List<MaterialModel>>(
        future: _fetchClassMaterials(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat materi: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final materials = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                SharedCard(
                  color: AppColors.cardLight,
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classItem.subjectName.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        classItem.className,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.vpn_key_rounded, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Kode Kelas: ${classItem.classCode}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  'Materi Pembelajaran Pintar',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 16),

                if (materials.isEmpty)
                  SharedCard(
                    color: AppColors.cardLight,
                    borderRadius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.menu_book_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum Ada Materi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Guru Anda belum mempublikasikan materi di kelas ini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: materials.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final material = materials[index];
                      return _buildMaterialCard(context, material, studentUid);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterialCard(BuildContext context, MaterialModel material, String studentUid) {
    return FutureBuilder<StudentProgressModel?>(
      future: _fetchStudentProgress(studentUid, material.materialId),
      builder: (context, progressSnapshot) {
        final progress = progressSnapshot.data;
        final isRead = progress?.isReadingCompleted ?? false;
        final isQuizDone = progress?.isQuizUtamaCompleted ?? false;

        return SharedCard(
          color: AppColors.cardLight,
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Material Read Area
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerPage(material: material),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              material.title,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isRead 
                                  ? 'Selesai Dibaca ✓' 
                                  : 'Format: ${material.fileType.toUpperCase()} • Ketuk untuk Membaca',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: isRead ? AppColors.success : Colors.grey.shade600,
                                fontWeight: isRead ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // 2. Quiz Utama Area
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isQuizDone 
                            ? Icons.check_circle_rounded 
                            : (isRead ? Icons.lock_open_rounded : Icons.lock_rounded),
                        color: isQuizDone 
                            ? AppColors.success 
                            : (isRead ? AppColors.primaryLight : Colors.grey.shade400),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isQuizDone 
                            ? 'Kuis Utama Selesai' 
                            : 'Kuis Utama',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isQuizDone 
                              ? AppColors.success 
                              : (isRead ? AppColors.textPrimaryLight : Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                  
                  // Mulai Kuis Button
                  isQuizDone
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Selesai',
                            style: GoogleFonts.outfit(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: isRead ? AppColors.primaryLight : Colors.grey.shade200,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: isRead
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BlocProvider(
                                        create: (context) => QuickCheckBloc(),
                                        child: QuickCheckPage(
                                          material: material,
                                          assessmentType: 'quiz_utama',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            'Mulai Kuis',
                            style: GoogleFonts.outfit(
                              color: isRead ? Colors.white : Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ],
              ),

              // 3. Sumber Belajar Tambahan Section
              FutureBuilder<List<LearningResourceModel>>(
                future: _fetchResources(material.materialId),
                builder: (context, resourcesSnapshot) {
                  final resources = resourcesSnapshot.data ?? [];
                  if (resources.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Sumber Belajar Tambahan',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...resources.map((res) {
                        IconData iconData = Icons.link_rounded;
                        Color iconColor = AppColors.primaryLight;
                        if (res.type == 'youtube') {
                          iconData = Icons.play_circle_fill_rounded;
                          iconColor = AppColors.error;
                        } else if (res.type == 'pdf' || res.type == 'file') {
                          iconData = Icons.picture_as_pdf_rounded;
                          iconColor = Colors.blue.shade600;
                        }

                        return Container(
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            leading: Icon(iconData, color: iconColor, size: 20),
                            title: Text(
                              res.title,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              res.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 11),
                            ),
                            trailing: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.grey),
                            onTap: () => _launchUrl(res.url),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
