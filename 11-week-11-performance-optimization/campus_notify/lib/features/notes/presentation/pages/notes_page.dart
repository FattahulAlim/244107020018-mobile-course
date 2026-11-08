import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/note.dart';
import '../providers/notes_providers.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: const [
          NotesCountBadge(),
        ],
      ),
      body: const NotesBody(),
    );
  }
}

class NotesCountBadge extends ConsumerWidget {
  const NotesCountBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optimasi Riverpod select: hanya rebuild saat jumlah item berubah
    final count = ref.watch(
      notesProvider.select((asyncVal) => asyncVal.value?.length ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count Catatan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class NotesBody extends ConsumerWidget {
  const NotesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(notesProvider),
      ),
      data: (notes) => notes.isEmpty
          ? const Center(child: Text('Belum ada catatan.'))
          : NotesList(notes),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      );
}

class NotesList extends StatefulWidget {
  const NotesList(this.notes, {super.key});
  final List<Note> notes;

  @override
  State<NotesList> createState() => _NotesListState();
}

class _NotesListState extends State<NotesList> {
  late final ScrollController _scrollController;
  int _displayedCount = 20;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _displayedCount = widget.notes.length > 20 ? 20 : widget.notes.length;
  }

  @override
  void didUpdateWidget(covariant NotesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes.length != widget.notes.length) {
      _displayedCount = widget.notes.length > 20 ? 20 : widget.notes.length;
    }
  }

  @override
  void dispose() {
    // Mencegah memory leak: controller selalu di-dispose
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Lazy loading saat mendekati akhir daftar (viewport budget)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_displayedCount < widget.notes.length) {
        setState(() {
          _displayedCount = (_displayedCount + 20).clamp(0, widget.notes.length);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMore = _displayedCount < widget.notes.length;

    return ListView.builder(
      controller: _scrollController,
      itemCount: _displayedCount + (hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _displayedCount) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return NoteItemTile(note: widget.notes[i]);
      },
    );
  }
}

class NoteItemTile extends StatelessWidget {
  const NoteItemTile({super.key, required this.note});
  final Note note;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: const Icon(Icons.note_alt_outlined),
          title: Text(
            note.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            note.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}