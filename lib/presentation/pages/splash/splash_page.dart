import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/guru_seeder.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Navigate to Login after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.85),
                  ]
                : [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerHigh,
                  ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Decorative background patterns
            Positioned(
              top: -size.height * 0.15,
              right: -size.width * 0.15,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              left: -size.width * 0.1,
              child: Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                ),
              ),
            ),
            
            // Content
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Opacity(
                      opacity: _opacityAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            'SI-FOKUS',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Sistem Informasi Fokus, Observasi,\ndan Kompetensi Ujian Siswa',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.4,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            
            // Footer loader
            Positioned(
              bottom: 60,
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white.withValues(alpha: 0.8),
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pilar Pendidikan Nasional',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.8),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 14),
                        label: const Text('Seed Data'),
                        onPressed: () async {
                          try {
                            // Impor secara lokal untuk menghindari circular reference
                            await _seedData(context);
                          } catch (e) {
                            _showSnackbar(context, 'Gagal seed data: $e');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade200,
                          backgroundColor: Colors.black.withValues(alpha: 0.2),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 14),
                        label: const Text('Clear Data'),
                        onPressed: () async {
                          try {
                            await _clearData(context);
                          } catch (e) {
                            _showSnackbar(context, 'Gagal hapus data: $e');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedData(BuildContext context) async {
    try {
      await GuruSeeder.seedAll();
      if (context.mounted) {
        _showSnackbar(context, 'Data dummy sukses disuntikkan ke database!');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackbar(context, 'Gagal seed data: $e');
      }
    }
  }

  Future<void> _clearData(BuildContext context) async {
    try {
      await GuruSeeder.clearAll();
      if (context.mounted) {
        _showSnackbar(context, 'Seluruh data dummy sukses dibersihkan.');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackbar(context, 'Gagal hapus data: $e');
      }
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
