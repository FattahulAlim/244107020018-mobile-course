import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/local/note.dart';
import '../data/models/post.dart';
import '../data/repositories/note_repository.dart';
import '../data/repositories/post_repository.dart';
import '../data/sync.dart';
import '../domain/usecases/search_notes_usecase.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/note_search_bar.dart';
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

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

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

// --- Search Feature State & Providers (Clean Architecture) ---

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final searchNotesUseCaseProvider = Provider<SearchNotesUseCase>(
  (ref) => const SearchNotesUseCase(),
);

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider);
  final useCase = ref.watch(searchNotesUseCaseProvider);

  return notesAsync.whenData((notes) => useCase.execute(notes, query));
});

// --- UI ---

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Catatan'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Judul Catatan',
              hintText: 'Masukkan judul',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Judul tidak boleh kosong';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                ref
                    .read(notesProvider.notifier)
                    .addNote(titleController.text.trim());
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotesAsync = ref.watch(filteredNotesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
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
        onPressed: () => _showAddNoteDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          NoteSearchBar(
            controller: _searchController,
            onChanged: (val) {
              ref.read(searchQueryProvider.notifier).setQuery(val);
            },
            onClear: () {
              ref.read(searchQueryProvider.notifier).clear();
            },
          ),
          Expanded(
            child: filteredNotesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (notes) {
                if (notes.isEmpty) {
                  if (searchQuery.isNotEmpty) {
                    return EmptyStateWidget(
                      message:
                          'Tidak ada catatan yang cocok dengan "$searchQuery"',
                      actionLabel: 'Hapus Pencarian',
                      onAction: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).clear();
                      },
                    );
                  }
                  return const EmptyStateWidget(
                    icon: Icons.note_alt_outlined,
                    message: 'Belum ada catatan.\nTekan tombol + untuk menambahkan catatan baru.',
                  );
                }

                return ListView(
                  children: [
                    ...notes.map(
                      (n) => NoteTile(
                        note: n,
                        onTap: () => context.push('/note/${n.id}'),
                        onDelete: () =>
                            ref.read(notesProvider.notifier).deleteNote(n.id!),
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Posts (cache-first)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    postsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Gagal load posts: $e'),
                      data: (posts) => Column(
                        children: posts
                            .map((p) => ListTile(title: Text(p.title)))
                            .toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
