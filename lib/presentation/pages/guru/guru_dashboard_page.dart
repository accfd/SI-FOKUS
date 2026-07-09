import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/class/class_bloc.dart';
import '../../bloc/class/class_event.dart';
import '../../bloc/class/class_state.dart';
import '../../../data/models/class_model.dart';
import '../../bloc/auth/auth_event.dart';

class GuruDashboardPage extends StatefulWidget {
  const GuruDashboardPage({super.key});

  @override
  State<GuruDashboardPage> createState() => _GuruDashboardPageState();
}

class _GuruDashboardPageState extends State<GuruDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Fetch classes for the logged in teacher
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ClassBloc>().add(FetchTeacherClasses(authState.user.uid));
    }
  }

  void _showCreateClassBottomSheet(BuildContext context, String teacherId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateClassBottomSheet(teacherId: teacherId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'SI-FOKUS Guru',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  user.name,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
            leading: const Icon(Icons.psychology_rounded, size: 28),
            actions: [
              IconButton(
                icon: const Icon(Icons.emoji_events_rounded),
                tooltip: 'Analisis Rekomendasi Bakat AI (F-08)',
                onPressed: () {
                  context.push('/dashboard/guru/talent');
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () {
                  context.read<AuthBloc>().add(const LogoutRequested());
                  context.go('/login');
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateClassBottomSheet(context, user.uid),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat Kelas Baru'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          body: BlocConsumer<ClassBloc, ClassState>(
            listener: (context, state) {
              if (state is ClassSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (state is ClassError) {
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
              if (state is ClassLoading && state is! TeacherClassesLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              List<ClassModel> classes = [];
              if (state is TeacherClassesLoaded) {
                classes = state.classes;
              } else {
                // Try to get class list from active bloc provider
                final blocState = context.read<ClassBloc>().state;
                if (blocState is TeacherClassesLoaded) {
                  classes = blocState.classes;
                }
              }

              if (classes.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.class_outlined,
                          size: 72,
                          color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Kelas',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Anda belum membuat kelas. Silakan ketuk tombol "Buat Kelas Baru" di bawah untuk memulai.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final classItem = classes[index];
                  return _buildClassCard(context, classItem, index);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildClassCard(BuildContext context, ClassModel classItem, int index) {
    final theme = Theme.of(context);
    
    // Choose gradient based on HSL tailored colors
    final List<Color> gradients = index % 3 == 0
        ? [const HSLColor.fromAHSL(1.0, 240, 0.8, 0.55).toColor(), const HSLColor.fromAHSL(1.0, 240, 0.8, 0.75).toColor()]
        : index % 3 == 1
            ? [const HSLColor.fromAHSL(1.0, 170, 0.8, 0.45).toColor(), const HSLColor.fromAHSL(1.0, 170, 0.8, 0.65).toColor()]
            : [const HSLColor.fromAHSL(1.0, 40, 0.9, 0.55).toColor(), const HSLColor.fromAHSL(1.0, 40, 0.9, 0.75).toColor()];

    return Card(
      elevation: 4,
      shadowColor: gradients[0].withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/dashboard/guru/class/${classItem.classId}');
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradients,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  classItem.classCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                classItem.className,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                classItem.subjectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${classItem.studentUids.length} Siswa',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateClassBottomSheet extends StatefulWidget {
  final String teacherId;

  const _CreateClassBottomSheet({required this.teacherId});

  @override
  State<_CreateClassBottomSheet> createState() => _CreateClassBottomSheetState();
}

class _CreateClassBottomSheetState extends State<_CreateClassBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _subjectNameController = TextEditingController();
  String _liveCodePreview = 'SIFKXXXX';

  @override
  void initState() {
    super.initState();
    _subjectNameController.addListener(_updateClassCodePreview);
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _subjectNameController.dispose();
    super.dispose();
  }

  void _updateClassCodePreview() {
    final text = _subjectNameController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _liveCodePreview = 'SIFKXXXX';
      });
      return;
    }

    String prefix = text.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    if (prefix.length > 4) {
      prefix = prefix.substring(0, 4);
    } else if (prefix.isEmpty) {
      prefix = 'SIFK';
    }

    final needed = 8 - prefix.length;
    final suffix = 'X' * needed;

    setState(() {
      _liveCodePreview = '$prefix$suffix';
    });
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<ClassBloc>().add(
            CreateClass(
              className: _classNameController.text,
              subjectName: _subjectNameController.text,
              teacherId: widget.teacherId,
            ),
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Buat Kelas Baru',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 20),
            
            // Name Field
            TextFormField(
              controller: _classNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kelas',
                hintText: 'Misal: Kelas VII-A',
                prefixIcon: Icon(Icons.class_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kelas tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Subject Field
            TextFormField(
              controller: _subjectNameController,
              decoration: const InputDecoration(
                labelText: 'Mata Pelajaran',
                hintText: 'Misal: Matematika',
                prefixIcon: Icon(Icons.book_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mata pelajaran tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Real-time Class Code Preview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key_rounded, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Code Preview:',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _liveCodePreview,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _onSubmit,
              child: const Text('Buat Kelas Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}
