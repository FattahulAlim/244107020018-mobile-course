import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prefs.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

/// Diisi dari main.dart sebelum app dibuka nilai terakhir dibuka
/// dari sesi SEBELUMNYA (bukan sesi yang sedang berjalan).
final previousLastOpenedProvider = Provider<String?>((ref) => null);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkModeAsync = ref.watch(darkModeProvider);
    final previousLastOpened = ref.watch(previousLastOpenedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Mode gelap'),
            value: darkModeAsync.value ?? false,
            onChanged: darkModeAsync.isLoading
                ? null
                : (_) => ref.read(darkModeProvider.notifier).toggle(),
          ),
          ListTile(
            title: const Text('Terakhir dibuka'),
            subtitle: Text(
              previousLastOpened == null
                  ? 'Baru pertama kali dibuka'
                  : DateTime.parse(previousLastOpened).toString(),
            ),
          ),
        ],
      ),
    );
  }
}