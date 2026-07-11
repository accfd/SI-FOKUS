import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/mock_db.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/shared_ui_kit.dart';

class ManageProfilePage extends StatefulWidget {
  const ManageProfilePage({super.key});

  @override
  State<ManageProfilePage> createState() => _ManageProfilePageState();
}

class _ManageProfilePageState extends State<ManageProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  bool get _isMockMode {
    try {
      return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
    } catch (_) {
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _nameController.text = authState.user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final newName = _nameController.text.trim();

    try {
      final updatedUser = user.copyWith(name: newName);
      if (_isMockMode) {
        await MockDb.save('users', user.uid, updatedUser.toJson());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': newName});
      }

      if (mounted) {
        context.read<AuthBloc>().add(const GetUserDataRequested());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: AppColors.primaryLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Keluar Akun?'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi SI-FOKUS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              context.read<AuthBloc>().add(const LogoutRequested());
              context.go('/login');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user;

        // Custom Role Label and Icon Color
        String roleLabel = 'Siswa';
        Color roleColor = AppColors.primaryLight;
        IconData roleIcon = Icons.school_rounded;

        if (user.role == 'guru') {
          roleLabel = 'Guru';
          roleColor = AppColors.secondaryLight;
          roleIcon = Icons.psychology_rounded;
        } else if (user.role == 'orang_tua') {
          roleLabel = 'Orang Tua';
          roleColor = AppColors.accentLight;
          roleIcon = Icons.family_restroom_rounded;
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: const SharedAppBar(
            title: 'Kelola Profil',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar & Profile Header
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: roleColor.withValues(alpha: 0.2),
                              width: 4,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: roleColor.withValues(alpha: 0.1),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: roleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Role Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: roleColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIcon, size: 16, color: roleColor),
                          const SizedBox(width: 6),
                          Text(
                            roleLabel.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: roleColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Form Card
                  SharedCard(
                    color: Colors.white,
                    borderRadius: 20,
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email Field (Read Only)
                        SharedInput(
                          labelText: 'Email Akun',
                          hintText: user.email,
                          prefixIcon: Icons.email_rounded,
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),

                        // Name Field (Editable)
                        SharedInput(
                          controller: _nameController,
                          labelText: 'Nama Lengkap',
                          hintText: 'Masukkan nama lengkap',
                          prefixIcon: Icons.person_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nama tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    SharedButton(
                      text: 'Simpan Perubahan',
                      onPressed: () => _saveProfile(user),
                      backgroundColor: AppColors.primaryLight,
                      icon: Icons.save_rounded,
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _onLogout(context),
                    icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                    label: Text(
                      'Keluar dari Akun',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
