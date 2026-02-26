import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/vote_provider.dart';
import '../utils/vote_error_handler.dart';
import 'markdown_content.dart';

class CommentItem extends ConsumerWidget {
  const CommentItem({super.key, required this.comment, this.onVote});

  final Comment comment;
  final VoidCallback? onVote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimUrl = ref.watch(authStateProvider.select((s) => s.claimUrl));
    return Padding(
      padding: EdgeInsets.only(left: (comment.depth * 16).toDouble(), bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                child: Text(
                  (comment.authorDisplayOrName.isNotEmpty ? comment.authorDisplayOrName[0] : '?').toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'u/${comment.authorDisplayOrName}',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (onVote != null) ...[
                          IconButton(
                            icon: Icon(
                              Icons.arrow_upward,
                              size: 16,
                              color: comment.userVote == VoteDirection.up ? Theme.of(context).colorScheme.primary : null,
                            ),
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              minimumSize: const Size(24, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () async {
                              debugPrint('[CommentItem] Upvote tapped for comment ${comment.id}');
                              ref.invalidate(voteCommentProvider((comment.id, true)));
                              final ok = await handleVote(context, () => ref.read(voteCommentProvider((comment.id, true)).future), claimUrl: claimUrl);
                              debugPrint('[CommentItem] Upvote result: $ok');
                              if (ok) onVote?.call();
                            },
                          ),
                          Text(
                            '${comment.score}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_downward,
                              size: 16,
                              color: comment.userVote == VoteDirection.down ? Theme.of(context).colorScheme.primary : null,
                            ),
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              minimumSize: const Size(24, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () async {
                              debugPrint('[CommentItem] Downvote tapped for comment ${comment.id}');
                              ref.invalidate(voteCommentProvider((comment.id, false)));
                              final ok = await handleVote(context, () => ref.read(voteCommentProvider((comment.id, false)).future), claimUrl: claimUrl);
                              debugPrint('[CommentItem] Downvote result: $ok');
                              if (ok) onVote?.call();
                            },
                          ),
                          const SizedBox(width: 4),
                        ] else
                          Text(
                            '${comment.score} pts',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    MarkdownContent(data: comment.content),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...comment.replies.map((c) => CommentItem(comment: c, onVote: onVote)),
          ],
        ],
      ),
    );
  }
}
