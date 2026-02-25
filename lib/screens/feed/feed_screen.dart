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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final feedAsync = ref.watch(feedPostsProvider(_sort));

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
            onPressed: () => ref.invalidate(feedPostsProvider(_sort)),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/submolts'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: PostSortChips(
              sort: _sort,
              onSortChanged: (s) => setState(() => _sort = s),
            ),
          ),
        ),
      ),
      body: PostsListBody(
        feedAsync: feedAsync,
        onRefresh: () async => ref.invalidate(feedPostsProvider(_sort)),
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
