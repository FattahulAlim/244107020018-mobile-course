import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class GetAnnouncement {
  const GetAnnouncement(this._repository);
  final AnnouncementRepository _repository;

  Future<({Announcement? announcement, Failure? failure})> call(String id) =>
      _repository.getAnnouncement(id);
}