import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import 'auth_provider.dart';

final feedPostsProvider = FutureProvider.family<List<Post>, PostSort>((ref, sort) async {
  final api = ref.watch(moltbookApiProvider);
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated) return [];

  final res = await api.getPosts(sort: sort);
  final data = res['data'] as List<dynamic>? ?? res['posts'] as List<dynamic>? ?? [];
  return data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
});
