import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'data/paged_post_page.dart';
import 'pages/post_detail_page.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

// Konfigurasi Router (Daftar Halaman)
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PagedPostPage(),
    ),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        // Mengambil ID dari parameter URL
        final id = int.parse(state.pathParameters['id']!);
        return PostDetailPage(postId: id);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Week 4 - REST API',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        routerConfig: _router, // Gunakan konfigurasi GoRouter
      );
}