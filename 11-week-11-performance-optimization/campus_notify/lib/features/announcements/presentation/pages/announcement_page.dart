import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../../domain/entities/announcement.dart';
import '../providers/announcement_providers.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pengumuman $id')),
      body: AnnouncementBody(id: id),
    );
  }
}

class AnnouncementBody extends ConsumerWidget {
  const AnnouncementBody({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementProvider(id));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('$e', textAlign: TextAlign.center),
        ),
      ),
      data: (a) => AnnouncementDetailView(announcement: a),
    );
  }
}

class AnnouncementDetailView extends StatelessWidget {
  const AnnouncementDetailView({super.key, required this.announcement});
  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (announcement.imageUrl != null &&
              announcement.imageUrl!.isNotEmpty) ...[
            RepaintBoundary(
              child: AnnouncementBannerImage(imageUrl: announcement.imageUrl!),
            ),
            const SizedBox(height: 16),
          ],
          RepaintBoundary(
            child: AnnouncementHeader(
              title: announcement.title,
              createdAt: announcement.createdAt,
            ),
          ),
          const Divider(height: 24),
          Text(
            announcement.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class AnnouncementHeader extends StatelessWidget {
  const AnnouncementHeader({
    super.key,
    required this.title,
    required this.createdAt,
  });

  final String title;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          formatTanggal(createdAt),
          style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class AnnouncementBannerImage extends StatelessWidget {
  const AnnouncementBannerImage({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        memCacheWidth: 600,
        memCacheHeight: 400,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
        placeholder: (context, url) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 120,
          color: Colors.grey[100],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
          ),
        ),
        fadeInDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}