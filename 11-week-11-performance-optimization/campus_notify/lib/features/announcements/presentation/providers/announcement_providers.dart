import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../infrastructures/core_providers.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcement.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(ref.watch(dioProvider)),
);

final getAnnouncementProvider = Provider<GetAnnouncement>(
  (ref) => GetAnnouncement(ref.watch(announcementRepositoryProvider)),
);

final announcementProvider =
    FutureProvider.family<Announcement, String>((ref, id) async {
  final result = await ref.watch(getAnnouncementProvider).call(id);
  if (result.failure != null) throw result.failure!;
  return result.announcement!;
});

final announcementsListProvider =
    FutureProvider.family<List<Announcement>, int>((ref, page) async {
  final repo = ref.watch(announcementRepositoryProvider);
  final result = await repo.getAnnouncements(page: page);
  if (result.failure != null && result.announcements.isEmpty) {
    throw result.failure!;
  }
  return result.announcements;
});