import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrangTuaDashboardPage extends StatelessWidget {
  const OrangTuaDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Orang Tua'),
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
                Icons.family_restroom_rounded,
                size: 80,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Selamat Datang, Orang Tua / Wali!',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Pantau perkembangan belajar anak, periksa raport AI, dan dapatkan rekomendasi pendampingan belajar di rumah.',
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
                        'Status Pemantauan Anak',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          _StatColumn(label: 'Fokus Belajar', value: 'Baik (82%)'),
                          _StatColumn(label: 'Konsistensi', value: 'Tinggi'),
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
