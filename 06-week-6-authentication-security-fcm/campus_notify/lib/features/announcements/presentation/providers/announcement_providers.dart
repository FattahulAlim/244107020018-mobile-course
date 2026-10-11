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