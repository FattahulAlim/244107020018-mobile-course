import 'package:dio/dio.dart';
import '../../../../core/failures.dart';
import '../../../../infrastructures/api_errors.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncement(
      String id) async {
    try {
      final res = await _dio.get('/announcements/$id');
      final model = AnnouncementModel.fromJson(res.data as Map<String, dynamic>);
      return (announcement: model, failure: null);
    } catch (e) {
      return (announcement: null, failure: NetworkFailure(friendlyMessage(e)));
    }
  }
}