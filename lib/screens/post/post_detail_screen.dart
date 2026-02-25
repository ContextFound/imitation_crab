import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/comment.dart';
import '../../models/post.dart';
import '../../providers/api_debug_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/vote_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider((widget.postId, _sort)));

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
        ],
      ),
      body: postAsync.when(
        data: (post) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PostHeader(
                      post: post,
                      postId: widget.postId,
                      onVote: () => ref.invalidate(postProvider(widget.postId)),
                    ),
                    const SizedBox(height: 16),
                    if (post.content != null && post.content!.isNotEmpty)
                      MarkdownContent(data: post.content!),
                    if (post.url != null && post.url!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse(post.url!)),
                        child: Row(
                          children: [
                            Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                post.url!,
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
                    commentsAsync.when(
                      data: (comments) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: comments
                            .map((c) => CommentItem(
                                  comment: c,
                                  onVote: () => ref.invalidate(postCommentsProvider((widget.postId, _sort))),
                                ))
                            .toList(),
                      ),
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                      error: (e, _) => SelectableText('Error: $e'),
                    ),
                  ],
                ),
              ),
            ),
            CommentComposer(
              postId: widget.postId,
              onSubmitted: () => ref.invalidate(postCommentsProvider((widget.postId, _sort))),
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
                await ref.read(votePostProvider((postId, true)).future);
                onVote();
              },
            ),
            Text('${post.score}'),
            IconButton(
              icon: Icon(Icons.arrow_downward, size: 20, color: post.userVote == VoteDirection.down ? Theme.of(context).colorScheme.primary : null),
              onPressed: () async {
                await ref.read(votePostProvider((postId, false)).future);
                onVote();
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
