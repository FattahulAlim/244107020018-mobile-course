import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/todo_page.dart';
import 'pages/stats_page.dart'; // Memakai StatsPage yang sudah dibuat sebelumnya

void main() => runApp(const ProviderScope(child: MyApp()));


final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // ShellRoute berfungsi membungkus halaman-halaman anak dengan sebuah UI tetap (seperti NavigationBar)
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const TodoPage(),
        ),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsPage(),
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router( // Memakai .router
        title: 'Week 3 - Navigation & State',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      );
}

// Membuat Layout utama yang menampung NavigationBar
class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child, // Digunakan untuk menampilkan halaman seperti halaman todopage atau statspage
      bottomNavigationBar: NavigationBar(
        // Menentukan tab mana yang aktif berdasarkan rute saat ini
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (int index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'ToDo'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Stats'),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/stats')) return 1;
    return 0; 
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/stats');
        break;
    }
  }
}

