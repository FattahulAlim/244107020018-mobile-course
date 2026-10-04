import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Debug', style: TextStyle(fontWeight: FontWeight.bold)),
            ValueListenableBuilder<String?>(
              valueListenable: fcmTokenPreview,
              builder: (_, token, _) => Text('FCM token: ${token ?? "-"}'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/pengumuman/1'),
              child: const Text('Buka pengumuman 1'),
            ),
          ],
        ),
      ),
    );
  }
}