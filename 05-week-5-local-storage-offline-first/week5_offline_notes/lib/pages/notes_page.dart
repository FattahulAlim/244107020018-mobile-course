import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/local/note.dart';
import '../data/models/post.dart';
import '../data/repositories/note_repository.dart';
import '../data/repositories/post_repository.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';
import 'settings_page.dart';

// --- Providers ---

final noteRepositoryProvider = Provider((ref) => NoteRepository());

final postRepositoryProvider = Provider((ref) => PostRepository(createDio()));

final postCacheRepositoryProvider = Provider(
  (ref) => PostCacheRepository(ref.watch(postRepositoryProvider)),
);

final dirtyCountProvider = FutureProvider<int>(
  (ref) => ref.watch(noteRepositoryProvider).countDirty(),
);

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final repo = ref.watch(postCacheRepositoryProvider);
  return repo.loadPostsCacheFirst(onUpdated: () => ref.invalidateSelf());
});

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() => ref.watch(noteRepositoryProvider).fetchNotes();

  Future<void> addNote(String title) async {
    await ref.read(noteRepositoryProvider).addNote(title: title);
    _refreshAll();
  }

  Future<void> deleteNote(int id) async {
    await ref.read(noteRepositoryProvider).deleteNote(id);
    _refreshAll();
  }

  Future<int> sync() async {
    final synced = await syncNotes(ref.read(noteRepositoryProvider));
    final freshNotes = await ref.read(noteRepositoryProvider).fetchNotes();
    state = AsyncData(freshNotes);
    ref.invalidate(dirtyCountProvider);
    return synced;
  }

  void _refreshAll() {
    ref.invalidateSelf();
    ref.invalidate(dirtyCountProvider);
  }
}

// --- UI ---

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notes (${dirtyAsync.value ?? 0} belum disync)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final synced = await ref.read(notesProvider.notifier).sync();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$synced note berhasil disync')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            ref.read(notesProvider.notifier).addNote('Note ${DateTime.now().second}'),
        child: const Icon(Icons.add),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) => ListView(
          children: [
            ...notes.map((n) => NoteTile(
                  note: n,
                  onTap: () => context.push('/note/${n.id}'),
                  onDelete: () => ref.read(notesProvider.notifier).deleteNote(n.id!),
                )),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Posts (cache-first)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            postsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Gagal load posts: $e'),
              data: (posts) =>
                  Column(children: posts.map((p) => ListTile(title: Text(p.title))).toList()),
            ),
          ],
        ),
      ),
    );
  }
}