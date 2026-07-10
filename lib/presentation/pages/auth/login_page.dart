import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../../data/repositories/seeder.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSeeding = false;

  void _onSeedData() async {
    setState(() {
      _isSeeding = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Mengunggah 35 siswa & 6 modul biologi ke Firebase...')),
          ],
        ),
        duration: Duration(minutes: 2),
      ),
    );

    try {
      await DatabaseSeeder.seedAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Sukses!'),
            ],
          ),
          content: const Text(
            'Data 35 Siswa, 1 Guru, dan 6 Modul Biologi (KD 3.1 - 3.6) telah berhasil disimpan ke Cloud Firestore Anda!\n\n'
            'Silakan masuk menggunakan akun berikut:\n'
            '• Guru: guru@sifokus.sch.id / 123456\n'
            '• Siswa: siswa@sifokus.sch.id / 123456\n'
            '• Orang Tua: ortu@sifokus.sch.id / 123456'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal seeding database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailController.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
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
                      theme.colorScheme.secondary.withValues(alpha: 0.05),
                      theme.colorScheme.surface,
                    ]
                  : [
                      theme.colorScheme.surface,
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                      theme.colorScheme.surface,
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative background circles
              Positioned(
                top: size.height * 0.15,
                left: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                bottom: size.height * 0.1,
                right: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              
              // Login Card with Glassmorphism
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // App Logo & Text
                              const Icon(
                                Icons.psychology_rounded,
                                size: 64,
                                color: Colors.indigo,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Masuk SI-FOKUS',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sistem Informasi Fokus, Observasi,\ndan Kompetensi Ujian Siswa',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // Email Input
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  hintText: 'nama@sekolah.sch.id',
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
                              
                              // Submit Button
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isLoading = state is AuthLoading;
                                  return ElevatedButton(
                                    onPressed: isLoading ? null : _onLogin,
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Masuk Aplikasi'),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Navigation to Register
                              OutlinedButton(
                                onPressed: () => context.push('/register'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  side: BorderSide(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Belum punya akun? Register'),
                              ),
                              if (kDebugMode) ...[
                                const SizedBox(height: 16),
                                // Seed Data Button
                                ElevatedButton.icon(
                                  onPressed: _isSeeding ? null : _onSeedData,
                                  icon: const Icon(Icons.cloud_upload_rounded),
                                  label: const Text('Seed 35 Siswa & 6 Modul ke Firebase'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                              
                              if (kDebugMode) ...[
                                // Quick testing options (in case Firebase is not connected yet)
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  'Akses Cepat Pengujian (Offline/Mock)',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _quickRoleButton(context, 'Guru', 'guru@sifokus.sch.id', '123456', theme.colorScheme.secondary),
                                    _quickRoleButton(context, 'Siswa', 'siswa@sifokus.sch.id', '123456', theme.colorScheme.primary),
                                    _quickRoleButton(context, 'OrangTua', 'ortu@sifokus.sch.id', '123456', theme.colorScheme.tertiary),
                                  ],
                                ),
                              ],
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

  Widget _quickRoleButton(BuildContext context, String title, String email, String password, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size.fromHeight(36),
            padding: EdgeInsets.zero,
          ),
          onPressed: () {
            context.read<AuthBloc>().add(
                  LoginRequested(
                    email: email,
                    password: password,
                  ),
                );
          },
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
