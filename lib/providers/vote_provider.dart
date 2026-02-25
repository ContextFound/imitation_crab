import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

final votePostProvider = FutureProvider.family<void, (String, bool)>((ref, params) async {
  final api = ref.read(moltbookApiProvider);
  final (postId, isUpvote) = params;
  if (isUpvote) {
    await api.upvotePost(postId);
  } else {
    await api.downvotePost(postId);
  }
});

final voteCommentProvider = FutureProvider.family<void, (String, bool)>((ref, params) async {
  final api = ref.read(moltbookApiProvider);
  final (commentId, isUpvote) = params;
  if (isUpvote) {
    await api.upvoteComment(commentId);
  } else {
    await api.downvoteComment(commentId);
  }
});
