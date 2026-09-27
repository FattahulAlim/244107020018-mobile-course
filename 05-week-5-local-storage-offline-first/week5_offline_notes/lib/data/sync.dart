import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'models/post.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_repository.dart';

/// --- Antrean sync notes (write path): dirty flag -> upload -> tandai bersih ---

Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  // Simulasi upload: pada project nyata, kirim tiap catatan dirty
  // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}

/// --- Cache-first posts (read path) ---

class PostCacheRepository {
  PostCacheRepository(this._postRepository, {Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final PostRepository _postRepository;
  final Future<Database> Function() _openDb;

  Future<List<Post>> loadPostsCacheFirst({void Function()? onUpdated}) async {
    final cached = await readCachedPosts();
    refreshPostsInBackground(onUpdated: onUpdated);
    return cached;
  }

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'cached_at DESC');
    return rows
        .map((row) => Post.fromJson(
              jsonDecode(row['payload'] as String) as Map<String, dynamic>,
            ))
        .toList();
  }

  void refreshPostsInBackground({void Function()? onUpdated}) {
    () async {
      try {
        final posts = await _postRepository.fetchPosts();
        final db = await _openDb();
        final now = DateTime.now().toIso8601String();

        final batch = db.batch();
        batch.delete('cached_posts');
        for (final post in posts) {
          batch.insert('cached_posts', {
            'id': post.id,
            'payload': jsonEncode(post.toJson()),
            'cached_at': now,
          });
        }
        await batch.commit(noResult: true);

        onUpdated?.call();
      } catch (e) {
        // Kalau offline / gagal fetch, biarkan saja — cache lama tetap dipakai.
      }
    }();
  }
}