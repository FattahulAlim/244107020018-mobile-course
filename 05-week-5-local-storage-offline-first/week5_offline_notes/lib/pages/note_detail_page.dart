import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/note.dart';
import 'notes_page.dart' show noteRepositoryProvider;

// Baca langsung dari repository lokal (bukan dari state halaman list).
final noteByIdProvider = FutureProvider.family<Note?, int>(
  (ref, id) => ref.watch(noteRepositoryProvider).getNote(id),
);

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.noteId});
  final int noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteByIdProvider(noteId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail catatan')),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (note) {
          if (note == null) {
            return const Center(child: Text('Catatan tidak ditemukan'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(note.body.isEmpty ? '(kosong)' : note.body),
                const SizedBox(height: 12),
                Text('Diupdate: ${note.updatedAt}',
                    style: Theme.of(context).textTheme.bodySmall),
                Text(note.dirty ? 'Status: belum disync' : 'Status: tersimpan',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }
}