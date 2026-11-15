import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

/// Fake repository terkendali untuk pengujian widget
class FakeWidgetNoteRepository implements NoteRepository {
  FakeWidgetNoteRepository({
    List<Note>? initialNotes,
    this.failFetch = false,
    this.failAdd = false,
  }) : _notes = initialNotes != null ? List.from(initialNotes) : [];

  final List<Note> _notes;
  final bool failFetch;
  final bool failAdd;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (failFetch) {
      return (notes: const <Note>[], failure: const LocalFailure('Simulasi error database'));
    }
    return (notes: List<Note>.unmodifiable(_notes), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    if (failAdd) {
      return (note: null, failure: const LocalFailure('Simulasi gagal insert'));
    }
    final newNote = Note(
      id: _notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    _notes.insert(0, newNote);
    return (note: newNote, failure: null);
  }
}

void main() {
  Widget buildTestableWidget({
    required NoteRepository repository,
  }) {
    return ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: NotesPage(),
      ),
    );
  }

  group('Pengujian Widget: Tampilan UI NotesPage', () {
    testWidgets('menampilkan judul halaman catatan dan badge', (tester) async {
      final fakeRepo = FakeWidgetNoteRepository(initialNotes: []);

      await tester.pumpWidget(buildTestableWidget(repository: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Catatan'), findsOneWidget);
      expect(find.text('0 Catatan'), findsOneWidget);
      expect(find.byKey(const Key('add-note-fab')), findsOneWidget);
    });

    testWidgets('menampilkan pesan kosong saat belum ada catatan', (tester) async {
      final fakeRepo = FakeWidgetNoteRepository(initialNotes: []);

      await tester.pumpWidget(buildTestableWidget(repository: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada catatan.'), findsOneWidget);
    });

    testWidgets('menampilkan daftar catatan ketika repository memiliki data', (tester) async {
      final fakeRepo = FakeWidgetNoteRepository(
        initialNotes: [
          Note(id: 1, title: 'Belajar Flutter Testing', body: 'Unit, Widget, Integrasi', updatedAt: DateTime.now()),
          Note(id: 2, title: 'Menyiapkan Laporan', body: 'Minggu 12 JTI', updatedAt: DateTime.now()),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(repository: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Belajar Flutter Testing'), findsOneWidget);
      expect(find.text('Menyiapkan Laporan'), findsOneWidget);
      expect(find.text('2 Catatan'), findsOneWidget);
    });

    testWidgets('menampilkan pesan error dan tombol Coba lagi saat fetch gagal', (tester) async {
      final fakeRepo = FakeWidgetNoteRepository(failFetch: true);

      await tester.pumpWidget(buildTestableWidget(repository: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Simulasi error database'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });
  });

  group('Pengujian Widget: Interaksi Pengguna & Form Tambah Catatan', () {
    testWidgets('menekan FAB membuka dialog tambah catatan', (tester) async {
      final fakeRepo = FakeWidgetNoteRepository(initialNotes: []);

      await tester.pumpWidget(buildTestableWidget(repository: fakeRepo));
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.byKey(const Key('add-note-fab')));
      await tester.pumpAndSettle();

      // Dialog terbuka
      expect(find.text('Tambah Catatan / Tugas'), findsOneWidget);
      expect(find.byKey(const Key('task-title-field')), findsOneWidget);
      expect(find.byKey(const Key('save-task-button')), findsOneWidget);
    });

    testWidgets('menolak input tidak valid (hanya spasi atau kosong) dan menampilkan pesan error', (tester) async {
      final fakeRepo = FakeWidgetNoteRepository(initialNotes: []);

      await tester.pumpWidget(buildTestableWidget(repository: fakeRepo));
      await tester.pumpAndSettle();

      // Buka dialog
      await tester.tap(find.byKey(const Key('add-note-fab')));
      await tester.pumpAndSettle();

      // Masukkan teks tidak valid (hanya spasi)
      await tester.enterText(find.byKey(const Key('task-title-field')), '   ');
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Pesan error validasi muncul dan dialog tetap terbuka
      expect(find.text('Judul tugas tidak boleh kosong'), findsOneWidget);
      expect(find.text('Tambah Catatan / Tugas'), findsOneWidget);
    });

    testWidgets('pengguna berhasil memasukkan judul valid dan catatan muncul di daftar', (tester) async {
      final fakeRepo = FakeWidgetNoteRepository(initialNotes: []);

      await tester.pumpWidget(buildTestableWidget(repository: fakeRepo));
      await tester.pumpAndSettle();

      // Buka dialog
      await tester.tap(find.byKey(const Key('add-note-fab')));
      await tester.pumpAndSettle();

      // Isi input teks valid
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Baca materi pengujian',
      );
      await tester.enterText(
        find.byKey(const Key('task-body-field')),
        'Latihan pengujian unit dan widget Flutter',
      );

      // Tekan tombol simpan
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Verifikasi dialog telah tertutup dan item baru muncul di UI
      expect(find.byKey(const Key('task-title-field')), findsNothing);
      expect(find.text('Baca materi pengujian'), findsOneWidget);
      expect(find.text('1 Catatan'), findsOneWidget);
    });
  });
}
