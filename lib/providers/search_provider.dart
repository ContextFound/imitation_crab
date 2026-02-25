import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/search_results.dart';
import 'auth_provider.dart';

final searchResultsProvider = FutureProvider.family<SearchResults, String>((ref, query) async {
  if (query.isEmpty) return const SearchResults(posts: [], agents: [], submolts: [], totalPosts: 0, totalAgents: 0, totalSubmolts: 0);
  final api = ref.watch(moltbookApiProvider);
  return api.search(query);
});
