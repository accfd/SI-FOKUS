import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.brightness == Brightness.light
                  ? [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.tertiary.withValues(alpha: 0.05),
                      theme.colorScheme.surface,
                    ]
                  : [
                      theme.colorScheme.surface,
                      theme.colorScheme.tertiary.withValues(alpha: 0.08),
                      theme.colorScheme.surface,
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative background patterns
              Positioned(
                top: -size.height * 0.1,
                right: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -size.height * 0.1,
                left: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              
              // Register Form Card
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 96.0, bottom: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.light
                              ? Colors.white.withValues(alpha: 0.45)
                              : Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.brightness == Brightness.light
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.08),
                            width: 1.5,
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Daftar SI-FOKUS',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Buat akun Anda untuk memantau, mendiagnosis, dan mendukung proses belajar anak bangsa.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Nama Lengkap Input
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Lengkap',
                                  prefixIcon: Icon(Icons.person_outline),
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
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
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
                                decoration: const InputDecoration(
                                  labelText: 'Daftar Sebagai',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                initialValue: _selectedRole,
                                items: const [
                                  DropdownMenuItem(value: 'siswa', child: Text('Siswa')),
                                  DropdownMenuItem(value: 'guru', child: Text('Guru')),
                                  DropdownMenuItem(value: 'orang_tua', child: Text('Orang Tua / Wali')),
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
                                  decoration: const InputDecoration(
                                    labelText: 'Parent Access Code Anak (6 Digit)',
                                    prefixIcon: Icon(Icons.key_rounded),
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
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
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
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Buat Akun'),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Back to Login
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Sudah punya akun? Masuk di sini'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
