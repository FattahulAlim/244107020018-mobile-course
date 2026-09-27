import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/prefs.dart';
import 'pages/settings_page.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefsRepo = PrefsRepository();
  final previousLastOpened = await prefsRepo.getLastOpened();
  await prefsRepo.markOpenedNow();

  runApp(
    ProviderScope(
      overrides: [previousLastOpenedProvider.overrideWithValue(previousLastOpened)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkModeAsync = ref.watch(darkModeProvider);
    final isDark = darkModeAsync.value ?? false;

    return MaterialApp.router(
      title: 'Offline Notes',
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.blue),
      darkTheme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}