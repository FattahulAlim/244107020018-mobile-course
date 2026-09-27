import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../models/post.dart';
import 'post_repository.dart';

class PostCacheRepository {
  PostCacheRepository(this._postRepository, {Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final PostRepository _postRepository;
  final Future<Database> Function() _openDb;

  /// Tampilkan cache dulu, lalu refresh dari API di background.
  /// [onUpdated] dipanggil setelah refresh background selesai (sukses).
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