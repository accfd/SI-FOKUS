import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/shared_ui_kit.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _accessCodeController = TextEditingController();
  
  String _selectedRole = 'siswa'; // default role
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.primaryLight, size: 20),
      suffixIcon: suffixIcon,
      labelStyle: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 14),
      hintStyle: GoogleFonts.outfit(color: AppColors.textSecondaryLight.withOpacity(0.5), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primaryLight.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primaryLight,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2.0,
        ),
      ),
    );
  }

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            SignUpRequested(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              role: _selectedRole,
              parentAccessCode: _selectedRole == 'orang_tua'
                  ? _accessCodeController.text
                  : null,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Buat Akun Baru'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registrasi Berhasil! Mengalihkan...'),
                backgroundColor: Colors.green,
              ),
            );
            final role = state.user.role;
            if (role == 'guru') {
              context.go('/dashboard/guru');
            } else if (role == 'orang_tua') {
              context.go('/dashboard/orangtua');
            } else {
              context.go('/dashboard/siswa');
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 40.0, bottom: 24.0),
            child: SharedCard(
              color: Colors.white,
              borderRadius: 24,
              border: Border.all(
                color: AppColors.primaryLight.withOpacity(0.15),
                width: 1.5,
              ),
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Daftar SI-FOKUS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buat akun Anda untuk memantau, mendiagnosis, dan mendukung proses belajar anak bangsa.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Nama Lengkap Input
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.outfit(color: AppColors.textPrimaryLight, fontSize: 14),
                      decoration: _buildInputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icons.person_outline,
                        hintText: 'Budi Santoso',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email Input
                    TextFormField(
                      controller: _emailController,
                      style: GoogleFonts.outfit(color: AppColors.textPrimaryLight, fontSize: 14),
                      decoration: _buildInputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icons.email_outlined,
                        hintText: 'budi@sekolah.sch.id',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Role Selection Dropdown
                    DropdownButtonFormField<String>(
                      style: GoogleFonts.outfit(color: AppColors.textPrimaryLight, fontSize: 14),
                      decoration: _buildInputDecoration(
                        labelText: 'Daftar Sebagai',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      initialValue: _selectedRole,
                      dropdownColor: Colors.white,
                      items: [
                        DropdownMenuItem(
                          value: 'siswa',
                          child: Text('Siswa', style: GoogleFonts.outfit(color: AppColors.textPrimaryLight)),
                        ),
                        DropdownMenuItem(
                          value: 'guru',
                          child: Text('Guru', style: GoogleFonts.outfit(color: AppColors.textPrimaryLight)),
                        ),
                        DropdownMenuItem(
                          value: 'orang_tua',
                          child: Text('Orang Tua / Wali', style: GoogleFonts.outfit(color: AppColors.textPrimaryLight)),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedRole = val ?? 'siswa';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Conditional Input: Parent Access Code (Only for Parent role)
                    if (_selectedRole == 'orang_tua') ...[
                      TextFormField(
                        controller: _accessCodeController,
                        style: GoogleFonts.outfit(color: AppColors.textPrimaryLight, fontSize: 14),
                        decoration: _buildInputDecoration(
                          labelText: 'Parent Access Code Anak (6 Digit)',
                          prefixIcon: Icons.key_rounded,
                          hintText: 'E.g., X8A9P1',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (_selectedRole == 'orang_tua') {
                            if (value == null || value.trim().isEmpty) {
                              return 'Masukkan kode akses anak Anda';
                            }
                            if (value.trim().length != 6) {
                              return 'Kode akses harus berisi 6 karakter alfanumerik';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Password Input
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.outfit(color: AppColors.textPrimaryLight, fontSize: 14),
                      decoration: _buildInputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icons.lock_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondaryLight,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Submit Register Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return ElevatedButton(
                          onPressed: isLoading ? null : _onRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Buat Akun',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Back to Login
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                      ),
                      child: Text(
                        'Sudah punya akun? Masuk di sini',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
