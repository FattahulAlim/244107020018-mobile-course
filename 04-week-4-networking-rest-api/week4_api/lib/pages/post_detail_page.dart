import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';
import '../data/paged_posts.dart';
import '../data/models/post.dart';
import '../data/network_errors.dart';
// import '../data/paged_post_page.dart'; // Untuk PagedCommentSheet jika diperlukan di halaman detail

// Provider cerdas untuk detail post
final postDetailProvider = FutureProvider.family<Post, int>((ref, id) async {
  // 1. Coba ambil dari state paged list yang sudah termuat di memory
  final pagedState = ref.read(pagedPostsProvider);
  final existingPost = pagedState.items.where((p) => p.id == id).firstOrNull;
  
  if (existingPost != null) {
    return existingPost; 
  }

  // 2. Jika tidak ada di memory (langsung dibuka dari URL), fetch lewat Dio
  final repository = ref.watch(postRepositoryProvider);
  return repository.fetchPost(id);
});

class PostDetailPage extends ConsumerWidget {
  final int postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postState = ref.watch(postDetailProvider(postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Post')),
      body: postState.when(
        data: (post) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title, 
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 16),
              Text(
                post.body, 
                style: Theme.of(context).textTheme.bodyLarge
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(friendlyErrorMessage(e))),
      ),
    );
  }
}