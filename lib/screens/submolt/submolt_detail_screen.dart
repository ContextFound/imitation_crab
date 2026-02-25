import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/post.dart';
import '../../models/submolt.dart';
import '../../providers/api_debug_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/submolt_provider.dart';
import '../../widgets/api_debug_dialog.dart';
import '../../widgets/markdown_content.dart';
import '../../widgets/posts_list_view.dart';

class SubmoltDetailScreen extends ConsumerStatefulWidget {
  const SubmoltDetailScreen({super.key, required this.submoltName});

  final String submoltName;

  @override
  ConsumerState<SubmoltDetailScreen> createState() => _SubmoltDetailScreenState();
}

class _SubmoltDetailScreenState extends ConsumerState<SubmoltDetailScreen> {
  PostSort _sort = PostSort.hot;

  @override
  Widget build(BuildContext context) {
    final submoltAsync = ref.watch(submoltProvider(widget.submoltName));
    final feedAsync = ref.watch(submoltFeedProvider((widget.submoltName, _sort)));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Submolt'),
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
            onPressed: () {
              ref.invalidate(submoltProvider(widget.submoltName));
              ref.invalidate(submoltFeedProvider((widget.submoltName, _sort)));
            },
          ),
        ],
      ),
      body: submoltAsync.when(
        data: (submolt) => NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('m/${submolt.displayOrName}', style: Theme.of(context).textTheme.headlineSmall),
                              if (submolt.description != null && submolt.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                MarkdownContent(data: submolt.description!),
                              ],
                              const SizedBox(height: 8),
                              Text('${submolt.subscriberCount} subscribers'),
                            ],
                          ),
                        ),
                        _SubscribeButton(submolt: submolt),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: PostSortChips(
                sort: _sort,
                onSortChanged: (s) => setState(() => _sort = s),
                availableSorts: const [PostSort.hot, PostSort.new_, PostSort.top],
              ),
            ),
          ],
          body: PostsListBody(
            feedAsync: feedAsync,
            onRefresh: () async => ref.invalidate(submoltFeedProvider((widget.submoltName, _sort))),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: SelectableText('Error: $e')),
      ),
    );
  }
}

class _SubscribeButton extends ConsumerStatefulWidget {
  const _SubscribeButton({required this.submolt});

  final Submolt submolt;

  @override
  ConsumerState<_SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends ConsumerState<_SubscribeButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isSubscribed = widget.submolt.isSubscribed ?? false;
    return FilledButton(
      onPressed: _isLoading ? null : () async {
        setState(() => _isLoading = true);
        try {
          final api = ref.read(moltbookApiProvider);
          if (isSubscribed) {
            await api.unsubscribeSubmolt(widget.submolt.name);
          } else {
            await api.subscribeSubmolt(widget.submolt.name);
          }
          ref.invalidate(submoltProvider(widget.submolt.name));
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      child: _isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(isSubscribed ? 'Unsubscribe' : 'Subscribe'),
    );
  }
}
