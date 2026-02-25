import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import '../models/submolt.dart';
import 'auth_provider.dart';

final submoltsListProvider = FutureProvider.family<List<Submolt>, SubmoltListSort>((ref, sort) async {
  final api = ref.watch(moltbookApiProvider);
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated) return [];
  final res = await api.getSubmolts(sort: sort);
  final data = res['data'] as List<dynamic>? ?? res['submolts'] as List<dynamic>? ?? [];
  return data.map((e) => Submolt.fromJson(e as Map<String, dynamic>)).toList();
});

final submoltProvider = FutureProvider.family<Submolt, String>((ref, name) async {
  final api = ref.watch(moltbookApiProvider);
  return api.getSubmolt(name);
});

final submoltFeedProvider = FutureProvider.family<List<Post>, (String, PostSort)>((ref, params) async {
  final api = ref.watch(moltbookApiProvider);
  final (name, sort) = params;
  final res = await api.getSubmoltFeed(name, sort: sort);
  final data = res['data'] as List<dynamic>? ?? res['posts'] as List<dynamic>? ?? [];
  return data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
});
