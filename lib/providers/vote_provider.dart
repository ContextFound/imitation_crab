import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

final votePostProvider = FutureProvider.family<void, (String, bool)>((ref, params) async {
  final api = ref.read(moltbookApiProvider);
  final (postId, isUpvote) = params;
  debugPrint('[votePostProvider] Calling ${isUpvote ? "upvote" : "downvote"} for post $postId');
  if (isUpvote) {
    await api.upvotePost(postId);
  } else {
    await api.downvotePost(postId);
  }
  debugPrint('[votePostProvider] Vote API call completed for post $postId');
});

final voteCommentProvider = FutureProvider.family<void, (String, bool)>((ref, params) async {
  final api = ref.read(moltbookApiProvider);
  final (commentId, isUpvote) = params;
  debugPrint('[voteCommentProvider] Calling ${isUpvote ? "upvote" : "downvote"} for comment $commentId');
  if (isUpvote) {
    await api.upvoteComment(commentId);
  } else {
    await api.downvoteComment(commentId);
  }
  debugPrint('[voteCommentProvider] Vote API call completed for comment $commentId');
});
