import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/domain/usecases/search_notes_usecase.dart';

void main() {
  final sampleNotes = [
    Note(
      id: 1,
      title: 'Daftar Belanja Mingguan',
      body: 'Beli susu, telur, dan roti tawar',
      updatedAt: DateTime(2026, 10, 1),
    ),
    Note(
      id: 2,
      title: 'Rencana Belanja Elektronik',
      body: 'Beli kabel USB-C dan mouse wireless',
      updatedAt: DateTime(2026, 10, 2),
    ),
    Note(
      id: 3,
      title: 'Tugas Mobile Programming',
      body: 'Selesaikan praktikum minggu 9 AI-assisted vibe coding',
      updatedAt: DateTime(2026, 10, 3),
    ),
  ];

  group('SearchNotesUseCase & filterNotes Unit Tests', () {
    const useCase = SearchNotesUseCase();

    test('filter abaikan huruf besar/kecil (case-insensitive)', () {
      final results = filterNotes(sampleNotes, 'belanja');
      expect(results, hasLength(2));
      expect(results.map((n) => n.id), containsAll([1, 2]));

      final resultsUpper = useCase.execute(sampleNotes, 'BELANJA');
      expect(resultsUpper, hasLength(2));
    });

    test('query tak cocok kembalikan kosong', () {
      final results = filterNotes(sampleNotes, 'zzz-tak-ada');
      expect(results, isEmpty);

      final resultsUseCase = useCase.execute(sampleNotes, 'xyz999');
      expect(resultsUseCase, isEmpty);
    });

    test('query kosong mengembalikan seluruh daftar catatan', () {
      final resultsEmpty = filterNotes(sampleNotes, '');
      expect(resultsEmpty, hasLength(3));

      final resultsWhitespaceOnly = useCase.execute(sampleNotes, '   ');
      expect(resultsWhitespaceOnly, hasLength(3));
    });

    test(
      'query dengan leading dan trailing whitespace di-trim dengan benar',
      () {
        final results = useCase.execute(sampleNotes, '   mobile   ');
        expect(results, hasLength(1));
        expect(results.first.id, equals(3));
      },
    );

    test('pencarian cocok pada teks di dalam body catatan', () {
      final results = filterNotes(sampleNotes, 'kabel USB');
      expect(results, hasLength(1));
      expect(results.first.id, equals(2));
    });
  });
}
