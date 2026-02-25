import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import 'auth_provider.dart';

/// Moltbook API ignores the `t` parameter, so we filter client-side by createdAt.
List<Post> _filterByTimePeriod(List<Post> posts, FeedTimePeriod period) {
  final now = DateTime.now().toUtc();
  final cutoff = switch (period) {
    FeedTimePeriod.hour => now.subtract(const Duration(hours: 1)),
    FeedTimePeriod.day => now.subtract(const Duration(days: 1)),
    FeedTimePeriod.week => now.subtract(const Duration(days: 7)),
  };
  return posts.where((p) {
    try {
      final created = DateTime.parse(p.createdAt).toUtc();
      return created.isAfter(cutoff);
    } catch (_) {
      return true; // keep if unparseable
    }
  }).toList();
}

final feedPostsProvider =
    FutureProvider.family<List<Post>, (PostSort, FeedTimePeriod)>((ref, args) async {
  final (sort, timePeriod) = args;
  final api = ref.watch(moltbookApiProvider);
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated) return [];

  // Request larger limit for "hour" to get enough posts after client-side filtering.
  final limit = timePeriod == FeedTimePeriod.hour ? 100 : (timePeriod == FeedTimePeriod.day ? 50 : 25);
  final res = await api.getPosts(sort: sort, limit: limit);
  final data = res['data'] as List<dynamic>? ?? res['posts'] as List<dynamic>? ?? [];
  final posts = data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  return _filterByTimePeriod(posts, timePeriod);
});
