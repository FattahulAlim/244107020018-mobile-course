import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../notifications/push_service.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../../routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: const [
          LogoutActionButton(),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DebugTokenCard(),
            SizedBox(height: 16),
            FeatureNavigationCards(),
          ],
        ),
      ),
    );
  }
}

class LogoutActionButton extends ConsumerWidget {
  const LogoutActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Keluar',
      onPressed: () async {
        await ref.read(authStateProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      },
    );
  }
}

class DebugTokenCard extends StatelessWidget {
  const DebugTokenCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Perangkat & Push Notification',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<String?>(
              valueListenable: fcmTokenPreview,
              builder: (_, token, _) => SelectableText(
                'FCM Token: ${token ?? "-"}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureNavigationCards extends StatelessWidget {
  const FeatureNavigationCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.campaign_outlined),
          onPressed: () => context.go('/pengumuman/1'),
          label: const Text('Buka Pengumuman 1 (Cached & Optimized Image)'),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.note_alt_outlined),
          onPressed: () => context.push(AppRoutes.notes),
          label: const Text('Buka Catatan (Lazy Loading & RepaintBoundary)'),
        ),
      ],
    );
  }
}