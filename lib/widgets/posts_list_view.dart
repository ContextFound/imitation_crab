import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import 'post_card.dart';

/// Reusable sort chips for post feeds (Hot, New, Top, Rising).
class PostSortChips extends StatelessWidget {
  const PostSortChips({
    super.key,
    required this.sort,
    required this.onSortChanged,
    this.availableSorts = const [PostSort.hot, PostSort.new_, PostSort.top, PostSort.rising],
  });

  final PostSort sort;
  final ValueChanged<PostSort> onSortChanged;
  final List<PostSort> availableSorts;

  static const Map<PostSort, String> _labels = {
    PostSort.hot: 'Hot',
    PostSort.new_: 'New',
    PostSort.top: 'Top',
    PostSort.rising: 'Rising',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final s in availableSorts)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_labels[s]!),
                selected: sort == s,
                onSelected: (_) => onSortChanged(s),
              ),
            ),
        ],
      ),
    );
  }
}

/// Reusable list-of-posts body for feed, submolt, and similar screens.
class PostsListBody extends StatelessWidget {
  const PostsListBody({
    super.key,
    required this.feedAsync,
    required this.onRefresh,
    this.emptyMessage = 'No posts yet',
    this.bottomPadding = 0,
  });

  final AsyncValue<List<Post>> feedAsync;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return feedAsync.when(
      data: (posts) => RefreshIndicator(
        onRefresh: onRefresh,
        child: posts.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 48),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.feed,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyMessage,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: posts.length + (bottomPadding > 0 ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == posts.length) {
                    return SizedBox(height: bottomPadding);
                  }
                  return PostCard(post: posts[i]);
                },
              ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SelectableText('Error: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => onRefresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
