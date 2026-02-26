import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/comment.dart';
import '../../models/post.dart';
import '../../providers/api_debug_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../utils/vote_error_handler.dart';
import '../../widgets/api_debug_dialog.dart';
import '../../widgets/comment_item.dart';
import '../../widgets/markdown_content.dart';
import '../../widgets/post_date.dart';
import 'comment_composer.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  CommentSort _sort = CommentSort.top;

  void _refresh() {
    debugPrint('[PostDetailScreen] _refresh called, invalidating postDetailProvider');
    ref.invalidate(postDetailProvider((widget.postId, _sort)));
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(postDetailProvider((widget.postId, _sort)));
    debugPrint('[PostDetailScreen] build: detailAsync state=${detailAsync.isLoading ? "loading" : detailAsync.hasValue ? "data(score=${detailAsync.value?.post.score}, userVote=${detailAsync.value?.post.userVote})" : "error"}');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Post'),
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
            onPressed: _refresh,
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PostHeader(
                      post: detail.post,
                      postId: widget.postId,
                      onVote: _refresh,
                    ),
                    const SizedBox(height: 16),
                    if (detail.post.content != null && detail.post.content!.isNotEmpty)
                      MarkdownContent(data: detail.post.content!),
                    if (detail.post.url != null && detail.post.url!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse(detail.post.url!)),
                        child: Row(
                          children: [
                            Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                detail.post.url!,
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 32),
                    Row(
                      children: [
                        _SortChip(label: 'Top', sort: CommentSort.top, selected: _sort, onSelect: () => setState(() => _sort = CommentSort.top)),
                        _SortChip(label: 'New', sort: CommentSort.new_, selected: _sort, onSelect: () => setState(() => _sort = CommentSort.new_)),
                        _SortChip(label: 'Controversial', sort: CommentSort.controversial, selected: _sort, onSelect: () => setState(() => _sort = CommentSort.controversial)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: detail.comments
                          .map((c) => CommentItem(
                                comment: c,
                                onVote: _refresh,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            CommentComposer(
              postId: widget.postId,
              onSubmitted: _refresh,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SelectableText('Error: $e'),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => context.pop(), child: const Text('Back')),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends ConsumerWidget {
  const _PostHeader({
    required this.post,
    required this.postId,
    required this.onVote,
  });

  final Post post;
  final String postId;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[PostHeader] build: score=${post.score}, userVote=${post.userVote}');
    final claimUrl = ref.watch(authStateProvider.select((s) => s.claimUrl));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.push('/m/${post.submolt}'),
              child: Text('m/${post.submolt}', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/u/${post.authorName}'),
              child: Text('u/${post.authorDisplayOrName}', style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(width: 8),
            PostDate(post: post),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: post.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post number copied'), duration: Duration(seconds: 2)),
                );
              },
              child: Icon(Icons.share_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          post.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_upward, size: 20, color: post.userVote == VoteDirection.up ? Theme.of(context).colorScheme.primary : null),
              onPressed: () async {
                debugPrint('[PostHeader] Upvote tapped for post $postId');
                final api = ref.read(moltbookApiProvider);
                final ok = await votePost(context, api, postId, isUpvote: true, claimUrl: claimUrl);
                debugPrint('[PostHeader] Upvote result: $ok');
                if (ok) onVote();
              },
            ),
            Text('${post.score}'),
            IconButton(
              icon: Icon(Icons.arrow_downward, size: 20, color: post.userVote == VoteDirection.down ? Theme.of(context).colorScheme.primary : null),
              onPressed: () async {
                debugPrint('[PostHeader] Downvote tapped for post $postId');
                final api = ref.read(moltbookApiProvider);
                final ok = await votePost(context, api, postId, isUpvote: false, claimUrl: claimUrl);
                debugPrint('[PostHeader] Downvote result: $ok');
                if (ok) onVote();
              },
            ),
            const SizedBox(width: 16),
            Icon(Icons.comment_outlined, size: 18),
            const SizedBox(width: 4),
            Text('${post.commentCount} comments'),
          ],
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.sort,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final CommentSort sort;
  final CommentSort selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = sort == selected;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelect(),
      ),
    );
  }
}
