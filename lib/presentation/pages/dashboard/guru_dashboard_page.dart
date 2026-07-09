import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GuruDashboardPage extends StatelessWidget {
  const GuruDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Guru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.supervised_user_circle_rounded,
                size: 80,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Selamat Datang, Guru!',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Kelola kelas, upload materi smart learning, generate AI assessments, dan analisis kompetensi siswa Anda.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Ringkasan Aktivitas Guru',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          _StatColumn(label: 'Kelas', value: '4'),
                          _StatColumn(label: 'Siswa', value: '120'),
                          _StatColumn(label: 'Materi', value: '18'),
                        ],
                      ),
                    ],
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

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
