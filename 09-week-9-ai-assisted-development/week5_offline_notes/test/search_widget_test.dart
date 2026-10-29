import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/models/post.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';
import 'package:week5_offline_notes/widgets/empty_state_widget.dart';
import 'package:week5_offline_notes/widgets/note_tile.dart';

class MockNoteRepository extends NoteRepository {
  MockNoteRepository(this.notes)
    : super(openDb: () => throw UnimplementedError());

  final List<Note> notes;

  @override
  Future<List<Note>> fetchNotes() async => notes;

  @override
  Future<int> countDirty() async => notes.where((n) => n.dirty).length;
}

void main() {
  final sampleNotes = [
    Note(
      id: 1,
      title: 'Beli Susu Segar',
      body: 'Ke minimarket dekat rumah',
      updatedAt: DateTime(2026, 10, 1),
    ),
    Note(
      id: 2,
      title: 'Kuliah Pemrograman Mobile',
      body: 'Mengerjakan codelab minggu 9',
      updatedAt: DateTime(2026, 10, 2),
    ),
  ];

  Widget buildTestWidget({List<Note>? notes}) {
    return ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          MockNoteRepository(notes ?? sampleNotes),
        ),
        postsProvider.overrideWith((ref) => Future.value(<Post>[])),
      ],
      child: const MaterialApp(home: NotesPage()),
    );
  }

  testWidgets('Menampilkan search bar dan semua catatan awal', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('note_search_field')), findsOneWidget);
    expect(find.byType(NoteTile), findsNWidgets(2));
    expect(find.text('Beli Susu Segar'), findsOneWidget);
    expect(find.text('Kuliah Pemrograman Mobile'), findsOneWidget);
  });

  testWidgets('Menyaring catatan sesuai input query di search bar', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final searchField = find.byKey(const Key('note_search_field'));
    await tester.enterText(searchField, 'susu');
    await tester.pumpAndSettle();

    expect(find.byType(NoteTile), findsOneWidget);
    expect(find.text('Beli Susu Segar'), findsOneWidget);
    expect(find.text('Kuliah Pemrograman Mobile'), findsNothing);
  });

  testWidgets('Menampilkan empty state saat query pencarian tidak cocok', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final searchField = find.byKey(const Key('note_search_field'));
    await tester.enterText(searchField, 'tidak_ada_keyword_ini');
    await tester.pumpAndSettle();

    expect(find.byType(NoteTile), findsNothing);
    expect(find.byType(EmptyStateWidget), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(EmptyStateWidget),
        matching: find.textContaining('tidak_ada_keyword_ini'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Tombol Hapus Pencarian mengembalikan seluruh catatan', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final searchField = find.byKey(const Key('note_search_field'));
    await tester.enterText(searchField, 'xyz_not_found');
    await tester.pumpAndSettle();

    expect(find.byType(NoteTile), findsNothing);

    // Tekan tombol Hapus Pencarian di empty state
    final clearActionButton = find.text('Hapus Pencarian');
    expect(clearActionButton, findsOneWidget);
    await tester.tap(clearActionButton);
    await tester.pumpAndSettle();

    // Seluruh catatan muncul kembali
    expect(find.byType(NoteTile), findsNWidgets(2));
    expect(find.text('Beli Susu Segar'), findsOneWidget);
  });

  testWidgets('Menampilkan empty state awal ketika database kosong', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(notes: []));
    await tester.pumpAndSettle();

    expect(find.byType(NoteTile), findsNothing);
    expect(find.byType(EmptyStateWidget), findsOneWidget);
    expect(find.textContaining('Belum ada catatan'), findsOneWidget);
  });
}
