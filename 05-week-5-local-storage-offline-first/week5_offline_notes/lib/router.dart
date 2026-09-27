import 'package:go_router/go_router.dart';
import 'pages/notes_page.dart';
import 'pages/note_detail_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const NotesPage()),
    GoRoute(
      path: '/note/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return NoteDetailPage(noteId: id);
      },
    ),
  ],
);