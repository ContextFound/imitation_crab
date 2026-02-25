import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/post.dart';
import '../../providers/api_debug_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../widgets/api_debug_dialog.dart';
import '../../widgets/posts_list_view.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  PostSort _sort = PostSort.hot;
  FeedTimePeriod _timePeriod = FeedTimePeriod.day;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final feedAsync = ref.watch(feedPostsProvider((_sort, _timePeriod)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('imitationCrab'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'API Debug',
              onPressed: () {
                final record = ref.read(apiDebugNotifierProvider).latest;
                if (record == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No API calls recorded yet')),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => ApiDebugDialog(record: record),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(feedPostsProvider((_sort, _timePeriod))),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.account_tree),
            onPressed: () => context.push('/submolts'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: PostSortChips(
                    sort: _sort,
                    onSortChanged: (s) => setState(() => _sort = s),
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<FeedTimePeriod>(
                    value: _timePeriod,
                    isDense: true,
                    icon: const Icon(Icons.schedule, size: 20),
                    items: FeedTimePeriod.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.label),
                          ),
                        )
                        .toList(),
                    onChanged: (p) {
                      if (p != null) setState(() => _timePeriod = p);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: PostsListBody(
        feedAsync: feedAsync,
        onRefresh: () async => ref.invalidate(feedPostsProvider((_sort, _timePeriod))),
        bottomPadding: 80,
      ),
      floatingActionButton: authState.isAuthenticated
          ? FloatingActionButton(
              onPressed: () => context.push('/post/create'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
