import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/domain/usecases/get_notes.dart';

// -------------------------------------------------------------
// Skenario Codelab Step 3: Pengujian Kode Asinkron & Dependensi
// -------------------------------------------------------------

abstract interface class TaskRepository {
  Future<List<String>> getTasks();
  Future<void> addTask(String title);
}

class TaskService {
  TaskService(this._repository);

  final TaskRepository _repository;

  Future<List<String>> loadTasks() {
    return _repository.getTasks();
  }

  Future<void> addNewTask(String title) {
    return _repository.addTask(title);
  }
}

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({List<String>? tasks, this.error})
    : _tasks = tasks != null ? List.from(tasks) : [];

  final List<String> _tasks;
  final Exception? error;

  @override
  Future<List<String>> getTasks() async {
    if (error != null) throw error!;
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> addTask(String title) async {
    if (error != null) throw error!;
    _tasks.add(title);
  }
}

// -------------------------------------------------------------
// Skenario CampusNotify Clean Architecture: FakeNoteRepository
// -------------------------------------------------------------

class FakeCompleteNoteRepository implements NoteRepository {
  FakeCompleteNoteRepository({
    List<Note>? initialNotes,
    this.failureOnFetch,
    this.failureOnAdd,
  }) : _notes = initialNotes != null ? List.from(initialNotes) : [];

  final List<Note> _notes;
  final Failure? failureOnFetch;
  final Failure? failureOnAdd;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (failureOnFetch != null) {
      return (notes: const <Note>[], failure: failureOnFetch);
    }
    return (notes: List<Note>.unmodifiable(_notes), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    if (failureOnAdd != null) {
      return (note: null, failure: failureOnAdd);
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
  group('TaskService dengan FakeTaskRepository (Codelab Model)', () {
    test('meneruskan data dari repository secara sukses', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository(
        tasks: ['Baca materi Flutter', 'Mengerjakan Codelab'],
      );
      final service = TaskService(fakeRepo);

      // Act
      final result = await service.loadTasks();

      // Assert
      expect(result, ['Baca materi Flutter', 'Mengerjakan Codelab']);
    });

    test(
      'melempar exception saat repository mengalami error jaringan/server',
      () async {
        // Arrange
        final fakeRepo = FakeTaskRepository(
          error: Exception('Gagal terhubung ke server'),
        );
        final service = TaskService(fakeRepo);

        // Act & Assert (memastikan error tidak hilang diam-diam menjadi list kosong)
        expect(
          () async => await service.loadTasks(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Gagal terhubung ke server'),
            ),
          ),
        );
      },
    );

    test('berhasil menambahkan task baru ke fake repository', () async {
      final fakeRepo = FakeTaskRepository(tasks: ['Task A']);
      final service = TaskService(fakeRepo);

      await service.addNewTask('Task B');
      final updated = await service.loadTasks();

      expect(updated, ['Task A', 'Task B']);
    });
  });

  group('Clean Architecture: GetNotes & FakeCompleteNoteRepository', () {
    test(
      'GetNotes mengembalikan daftar entitas catatan dengan benar',
      () async {
        // Arrange
        final notes = [
          Note(
            id: 1,
            title: 'Kuliah Pemrograman Mobile',
            updatedAt: DateTime(2026, 11, 15),
          ),
          Note(
            id: 2,
            title: 'Praktikum Minggu 12 Testing',
            updatedAt: DateTime(2026, 11, 15),
          ),
        ];
        final fakeRepo = FakeCompleteNoteRepository(initialNotes: notes);
        final usecase = GetNotes(fakeRepo);

        // Act
        final response = await usecase.call();

        // Assert
        expect(response.failure, isNull);
        expect(response.notes.length, 2);
        expect(response.notes.first.title, 'Kuliah Pemrograman Mobile');
      },
    );

    test('GetNotes meneruskan kegagalan (LocalFailure) saat database gagal diakses', () async {
      // Arrange
      final fakeRepo = FakeCompleteNoteRepository(
        failureOnFetch: const LocalFailure('Database SQLite terkunci'),
      );
      final usecase = GetNotes(fakeRepo);

      // Act
      final response = await usecase.call();

      // Assert
      expect(response.notes, isEmpty);
      expect(response.failure, isA<LocalFailure>());
      expect(response.failure!.message, 'Database SQLite terkunci');
    });

    test(
      'addNote berhasil menyimpan entitas baru ke dalam repositori',
      () async {
        // Arrange
        final fakeRepo = FakeCompleteNoteRepository();

        // Act
        final addResult = await fakeRepo.addNote(
          title: 'Pengujian Integrasi',
          body: 'Memverifikasi end-to-end flow',
        );
        final fetchResult = await fakeRepo.fetchNotes();

        // Assert
        expect(addResult.failure, isNull);
        expect(addResult.note, isNotNull);
        expect(addResult.note!.title, 'Pengujian Integrasi');
        expect(fetchResult.notes.length, 1);
        expect(fetchResult.notes.first.body, 'Memverifikasi end-to-end flow');
      },
    );

    test('addNote meneruskan failure saat penyimpanan data gagal', () async {
      // Arrange
      final fakeRepo = FakeCompleteNoteRepository(
        failureOnAdd: const LocalFailure('Gagal menulis ke storage lokal'),
      );

      // Act
      final result = await fakeRepo.addNote(title: 'Catatan Rusak');

      // Assert
      expect(result.note, isNull);
      expect(result.failure, isA<LocalFailure>());
      expect(result.failure!.message, 'Gagal menulis ke storage lokal');
    });
  });
}
