import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import 'auth_provider.dart';

/// Client-side time filter. Only meaningful for Top sort.
List<Post> _filterByTimePeriod(List<Post> posts, FeedTimePeriod period) {
  if (period == FeedTimePeriod.all) return posts;
  final now = DateTime.now().toUtc();
  final cutoff = switch (period) {
    FeedTimePeriod.all => now,
    FeedTimePeriod.hour => now.subtract(const Duration(hours: 1)),
    FeedTimePeriod.day => now.subtract(const Duration(days: 1)),
    FeedTimePeriod.week => now.subtract(const Duration(days: 7)),
  };
  return posts.where((p) {
    try {
      return DateTime.parse(p.createdAt).toUtc().isAfter(cutoff);
    } catch (_) {
      return true;
    }
  }).toList();
}

final feedPostsProvider =
    FutureProvider.family<List<Post>, (PostSort, FeedTimePeriod)>((ref, args) async {
  final (sort, timePeriod) = args;
  final api = ref.watch(moltbookApiProvider);
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated) return [];

  // Time filter only applies to Top sort; other sorts have built-in recency.
  final applyTimeFilter = sort.hasTimePeriod && timePeriod != FeedTimePeriod.all;
  final limit = applyTimeFilter ? 100 : 25;
  final t = applyTimeFilter ? timePeriod.apiValue : null;

  final res = await api.getPosts(sort: sort, limit: limit, t: t);
  final data = res['data'] as List<dynamic>? ?? res['posts'] as List<dynamic>? ?? [];
  final posts = data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  return applyTimeFilter ? _filterByTimePeriod(posts, timePeriod) : posts;
});
