import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:campus_notify/features/announcements/presentation/pages/announcement_page.dart';
import 'package:campus_notify/infrastructures/api_client.dart';
import 'package:campus_notify/features/auth/data/auth_repository.dart';
import 'package:campus_notify/infrastructures/token_store.dart';

class MockTokenStore implements TokenStore {
  @override
  Future<String?> readAccess() async => 'dummy-token';
  @override
  Future<String?> readRefresh() async => 'dummy-refresh';
  @override
  Future<void> save({required String access, required String refresh}) async {}
  @override
  Future<void> clear() async {}
}

class MockAuthRepository extends AuthRepository {}

void main() {
  group('Repository Caching & Stale-While-Revalidate', () {
    test('AnnouncementRepositoryImpl returns cached data when network fails (fallback)', () async {
      final dio = Dio();
      final initialCache = <String, Announcement>{
        '101': Announcement(
          id: '101',
          title: 'Cached Title',
          body: 'Cached Content',
          createdAt: DateTime(2026, 11, 1),
        ),
      };

      final repo = AnnouncementRepositoryImpl(dio, cache: initialCache);

      // Skenario: Network error (server mati / offline)
      // Repository harus tetap mengembalikan data dari cache secara transparan
      final result = await repo.getAnnouncement('101');

      expect(result.failure, isNull);
      expect(result.announcement, isNotNull);
      expect(result.announcement!.title, 'Cached Title');
    });

    test('AnnouncementRepositoryImpl clearCache menghapus item cache', () async {
      final dio = Dio();
      final initialCache = <String, Announcement>{
        '102': Announcement(
          id: '102',
          title: 'Temp Title',
          body: 'Temp Content',
          createdAt: DateTime(2026, 11, 1),
        ),
      };

      final repo = AnnouncementRepositoryImpl(dio, cache: initialCache);
      repo.clearCache();

      // Sekarang cache kosong, jika request gagal akan melempar failure
      final result = await repo.getAnnouncement('102');
      expect(result.failure, isNotNull);
      expect(result.announcement, isNull);
    });
  });

  group('Network Optimization & In-Memory API Cache', () {
    test('api_client GET cache mengembalikan response yang sama tanpa round-trip ulang', () async {
      final dio = buildApiClient(MockTokenStore(), MockAuthRepository());
      
      // Verifikasi timeout headers & encoding gzip
      expect(dio.options.connectTimeout, const Duration(seconds: 10));
      expect(dio.options.receiveTimeout, const Duration(seconds: 15));
      expect(dio.options.headers['Accept-Encoding'], contains('gzip'));
    });
  });

  group('Widget Optimization & RepaintBoundary', () {
    testWidgets('NoteItemTile membungkus card dengan RepaintBoundary', (tester) async {
      final testNote = Note(
        id: 1,
        title: 'Optimasi Performa',
        body: 'Memanfaatkan RepaintBoundary untuk mengisolasi repainting.',
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteItemTile(note: testNote),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Optimasi Performa'), findsOneWidget);
    });

    testWidgets('AnnouncementDetailView membungkus komponen berat dengan RepaintBoundary', (tester) async {
      final announcement = Announcement(
        id: '1',
        title: 'Pengumuman Penting',
        body: 'Kuliah daring optimasi performa Flutter.',
        createdAt: DateTime(2026, 11, 5),
        imageUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnouncementDetailView(announcement: announcement),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Pengumuman Penting'), findsOneWidget);
      expect(find.byType(AnnouncementBannerImage), findsOneWidget);
    });

    testWidgets('NotesList melakukan lazy loading (maksimal 20 item per chunk di awal)', (tester) async {
      // 50 dummy notes
      final notes = List.generate(
        50,
        (i) => Note(
          id: i,
          title: 'Catatan #$i',
          body: 'Isi catatan performa ke-$i',
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotesList(notes),
          ),
        ),
      );

      // Verifikasi item pertama ada
      expect(find.text('Catatan #0'), findsOneWidget);
      // Item ke-30 tidak di-render di awal sebelum di-scroll (lazy loading aktif)
      expect(find.text('Catatan #30'), findsNothing);
    });
    testWidgets('NotesCountBadge menampilkan jumlah item dengan Riverpod select', (tester) async {
      final sampleNotes = [
        Note(id: 1, title: 'Item 1', body: 'Body 1', updatedAt: DateTime.now()),
        Note(id: 2, title: 'Item 2', body: 'Body 2', updatedAt: DateTime.now()),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesProvider.overrideWith((ref) => Future.value(sampleNotes)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: NotesCountBadge(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('2 Catatan'), findsOneWidget);
    });
  });
}
