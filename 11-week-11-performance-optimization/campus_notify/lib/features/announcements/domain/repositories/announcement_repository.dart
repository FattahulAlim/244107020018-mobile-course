import '../../../../core/failures.dart';
import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<({Announcement? announcement, Failure? failure})> getAnnouncement(
      String id);
  Future<({List<Announcement> announcements, Failure? failure})>
      getAnnouncements({int page = 1, int limit = 10});
}