import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

/// Repository terkendali dalam memori untuk skenario Integration Test
class InMemoryIntegrationNoteRepository implements NoteRepository {
  final List<Note> _notes = [];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    return (notes: List<Note>.unmodifiable(_notes), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: _notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    _notes.insert(0, note);
    return (note: note, failure: null);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('alur integrasi end-to-end: pengguna dapat menambahkan tugas/catatan dan melihatnya di daftar', (tester) async {
    final repo = InMemoryIntegrationNoteRepository();

    // Jalankan root widget halaman fitur
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: NotesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi kondisi awal (empty state)
    expect(find.text('Belum ada catatan.'), findsOneWidget);
    expect(find.text('0 Catatan'), findsOneWidget);

    // 1. Ketuk tombol FAB tambah catatan
    final fabFinder = find.byKey(const Key('add-note-fab'));
    expect(fabFinder, findsOneWidget);
    await tester.tap(fabFinder);
    await tester.pumpAndSettle();

    // 2. Masukkan judul dan deskripsi catatan sesuai skenario codelab
    final titleField = find.byKey(const Key('task-title-field'));
    expect(titleField, findsOneWidget);
    await tester.enterText(titleField, 'Baca materi');

    final bodyField = find.byKey(const Key('task-body-field'));
    expect(bodyField, findsOneWidget);
    await tester.enterText(bodyField, 'Persiapan QA dan Pengujian Aplikasi Flutter');

    // 3. Ketuk tombol Simpan
    final saveButton = find.byKey(const Key('save-task-button'));
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // 4. Verifikasi bahwa form telah tertutup dan catatan baru tampil pada daftar
    expect(find.byKey(const Key('task-title-field')), findsNothing);
    expect(find.text('Baca materi'), findsOneWidget);
    expect(find.text('Persiapan QA dan Pengujian Aplikasi Flutter'), findsOneWidget);
    expect(find.text('1 Catatan'), findsOneWidget);
  });
}
