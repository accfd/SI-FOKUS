import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../data/models/class_model.dart';
import '../../../../data/models/material_model.dart';
import '../../../../data/repositories/mock_db.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../siswa/leaderboard_page.dart';
import '../siswa/pdf_viewer_page.dart';
import '../siswa/profile_siswa_page.dart';
import '../siswa/quick_check_page.dart';
import '../siswa/siswa_class_detail_page.dart';
import '../../bloc/gamification/gamification_bloc.dart';
import '../../bloc/learning_profile/learning_profile_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/shared_ui_kit.dart';

class SiswaDashboardPage extends StatefulWidget {
  const SiswaDashboardPage({super.key});

  @override
  State<SiswaDashboardPage> createState() => _SiswaDashboardPageState();
}

class _SiswaDashboardPageState extends State<SiswaDashboardPage> {
  Key _futureBuilderKey = UniqueKey();

  bool get _isMockMode {
    try {
      return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
    } catch (_) {
      return true;
    }
  }

  Future<List<ClassModel>> _fetchStudentClasses(String studentUid) async {
    if (_isMockMode) {
      final allClasses = await MockDb.getAll('classes');
      return allClasses
          .where((c) {
            final uids = c['studentUids'] as List<dynamic>?;
            return uids != null && uids.contains(studentUid);
          })
          .map((c) => ClassModel.fromJson(c))
          .toList();
    }

    final query = await FirebaseFirestore.instance
        .collection('classes')
        .where('studentUids', arrayContains: studentUid)
        .get();
    return query.docs.map((doc) => ClassModel.fromJson(doc.data())).toList();
  }

  Future<void> _showJoinClassDialog(BuildContext context, String studentUid) async {
    final textController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Gabung Kelas Baru',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Masukkan 8 karakter kode kelas yang diberikan oleh guru Anda.',
                    style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SharedInput(
                    controller: textController,
                    labelText: 'Kode Kelas',
                    hintText: 'Contoh: BIO10REG',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.outfit(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                ),
                isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: () async {
                          final code = textController.text.trim().toUpperCase();
                          if (code.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kode kelas tidak boleh kosong.')),
                            );
                            return;
                          }

                          setDialogState(() {
                            isLoading = true;
                          });

                          try {
                            if (_isMockMode) {
                              final allClasses = await MockDb.getAll('classes');
                              final matchIndex = allClasses.indexWhere((c) => (c['classCode'] as String).toUpperCase() == code);

                              if (matchIndex != -1) {
                                final classData = allClasses[matchIndex];
                                final uids = List<String>.from(classData['studentUids'] ?? []);
                                
                                if (uids.contains(studentUid)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Anda sudah bergabung di kelas ini.')),
                                  );
                                  Navigator.pop(dialogContext);
                                  return;
                                }

                                uids.add(studentUid);
                                classData['studentUids'] = uids;
                                await MockDb.save('classes', classData['classId'], classData);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Berhasil bergabung ke kelas ${classData['className']}!')),
                                );

                                setState(() {
                                  _futureBuilderKey = UniqueKey();
                                });
                                Navigator.pop(dialogContext);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Kode kelas tidak ditemukan.')),
                                );
                                setDialogState(() {
                                  isLoading = false;
                                });
                              }
                            } else {
                              final query = await FirebaseFirestore.instance
                                  .collection('classes')
                                  .where('classCode', isEqualTo: code)
                                  .limit(1)
                                  .get();

                              if (query.docs.isNotEmpty) {
                                final doc = query.docs.first;
                                final classData = doc.data();
                                final uids = List<String>.from(classData['studentUids'] ?? []);

                                if (uids.contains(studentUid)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Anda sudah bergabung di kelas ini.')),
                                  );
                                  Navigator.pop(dialogContext);
                                  return;
                                }

                                await FirebaseFirestore.instance
                                    .collection('classes')
                                    .doc(doc.id)
                                    .update({
                                  'studentUids': FieldValue.arrayUnion([studentUid])
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Berhasil bergabung ke kelas ${classData['className']}!')),
                                );

                                setState(() {
                                  _futureBuilderKey = UniqueKey();
                                });
                                Navigator.pop(dialogContext);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Kode kelas tidak ditemukan.')),
                                );
                                setDialogState(() {
                                  isLoading = false;
                                });
                              }
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal bergabung kelas: $e')),
                            );
                            setDialogState(() {
                              isLoading = false;
                            });
                          }
                        },
                        child: Text(
                          'Gabung',
                          style: GoogleFonts.outfit(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                        ),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: SharedAppBar(
        title: 'SI-FOKUS Siswa',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
              context.go('/login');
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is Authenticated) {
            final user = state.user;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Gamification Card
                  SharedCard(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 24,
                    color: AppColors.primaryLight,
                    border: Border.all(color: AppColors.primaryLight, width: 0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Halo, ${user.name}!',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem('XP', '${user.xp}', Icons.flash_on_rounded, Colors.amber),
                            _buildStatItem('Level', '${user.level}', Icons.military_tech_rounded, Colors.greenAccent),
                            _buildStatItem('Badges', '${user.unlockedBadges.length}', Icons.shield_rounded, Colors.orangeAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  Text(
                    'Fitur Belajar',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuCard(
                          context,
                          title: 'Profil\nBelajarku',
                          icon: Icons.analytics_rounded,
                          color: AppColors.primaryLight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider(
                                  create: (context) => LearningProfileBloc(),
                                  child: const ProfileSiswaPage(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMenuCard(
                          context,
                          title: 'Leaderboard\nKelas',
                          icon: Icons.leaderboard_rounded,
                          color: AppColors.accentLight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider(
                                  create: (context) => GamificationBloc(),
                                  child: const LeaderboardPage(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kelas Saya',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryLight, size: 20),
                        label: Text(
                          'Gabung Kelas',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        onPressed: () => _showJoinClassDialog(context, user.uid),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  FutureBuilder<List<ClassModel>>(
                    key: _futureBuilderKey,
                    future: _fetchStudentClasses(user.uid),
                    builder: (context, classSnapshot) {
                      if (classSnapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('Gagal memuat kelas: ${classSnapshot.error}'),
                        );
                      }
                      if (classSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final classes = classSnapshot.data ?? [];
                      if (classes.isEmpty) {
                        return SharedCard(
                          color: AppColors.cardLight,
                          borderRadius: 16,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'Anda belum bergabung di kelas manapun.\nSilakan hubungi guru Anda untuk didaftarkan.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 13, height: 1.4),
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: classes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final classItem = classes[index];
                          return SharedCard(
                            color: AppColors.cardLight,
                            padding: EdgeInsets.zero,
                            borderRadius: 16,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
                                child: const Icon(Icons.class_rounded, color: AppColors.primaryLight),
                              ),
                              title: Text(
                                classItem.className,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                'Mata Pelajaran: ${classItem.subjectName}',
                                style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SiswaClassDetailPage(classItem: classItem),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Gagal memuat profil.'));
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SharedCard(
      color: AppColors.cardLight,
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialCard(BuildContext context, {
    required String title,
    required bool isPdf,
  }) {
    return SharedCard(
      color: AppColors.cardLight,
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: InkWell(
        onTap: () {
          if (isPdf) {
            final dummyMaterial = MaterialModel(
              materialId: 'mat_demo_01',
              classId: 'cls_01',
              title: title,
              fileUrl: 'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
              fileType: 'pdf',
              createdAt: DateTime.now(),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfViewerPage(material: dummyMaterial),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hanya format PDF yang didukung saat ini.')),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPdf ? AppColors.error.withValues(alpha: 0.1) : AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf_rounded : Icons.article_rounded,
                  color: isPdf ? AppColors.error : AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modul Interaktif • Diunggah hari ini',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.grey.shade600,
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
    );
  }
}
