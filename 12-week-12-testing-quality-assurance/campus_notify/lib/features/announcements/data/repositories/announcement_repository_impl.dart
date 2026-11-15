import 'package:dio/dio.dart';
import '../../../../core/failures.dart';
import '../../../../infrastructures/api_errors.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl(this._dio, {Map<String, Announcement>? cache})
      : _cache = cache ?? <String, Announcement>{};

  final Dio _dio;
  final Map<String, Announcement> _cache;

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncement(
      String id) async {
    // 1. Cek cache (Stale-While-Revalidate: siapkan data lokal)
    final cached = _cache[id];

    // 2. Fetch fresh data dari network
    try {
      final res = await _dio.get('/announcements/$id');
      final model =
          AnnouncementModel.fromJson(res.data as Map<String, dynamic>);
      _cache[id] = model;
      return (announcement: model, failure: null);
    } catch (e) {
      // 3. Fallback: gunakan data cache jika jaringan bermasalah
      if (cached != null) {
        return (announcement: cached, failure: null);
      }
      return (announcement: null, failure: NetworkFailure(friendlyMessage(e)));
    }
  }

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
      getAnnouncements({int page = 1, int limit = 10}) async {
    try {
      final res = await _dio.get(
        '/announcements',
        queryParameters: {'page': page, 'limit': limit},
      );
      final list = (res.data as List)
          .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final item in list) {
        _cache[item.id] = item;
      }
      return (announcements: list, failure: null);
    } catch (e) {
      if (_cache.isNotEmpty) {
        return (announcements: _cache.values.toList(), failure: null);
      }
      return (
        announcements: const <Announcement>[],
        failure: NetworkFailure(friendlyMessage(e)),
      );
    }
  }

  void clearCache() => _cache.clear();
}