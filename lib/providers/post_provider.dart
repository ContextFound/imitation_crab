import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment.dart';
import '../models/post.dart';
import 'auth_provider.dart';

final postProvider = FutureProvider.family<Post, String>((ref, postId) async {
  final api = ref.watch(moltbookApiProvider);
  return api.getPost(postId);
});

final postCommentsProvider = FutureProvider.family<List<Comment>, (String, CommentSort)>((ref, params) async {
  final api = ref.watch(moltbookApiProvider);
  final (postId, sort) = params;
  return api.getComments(postId, sort: sort);
});

class PostDetail {
  const PostDetail({required this.post, required this.comments});
  final Post post;
  final List<Comment> comments;
}

final postDetailProvider = FutureProvider.family<PostDetail, (String, CommentSort)>((ref, params) async {
  final api = ref.watch(moltbookApiProvider);
  final (postId, sort) = params;
  final results = await Future.wait([
    api.getPost(postId),
    api.getComments(postId, sort: sort),
  ]);
  final detail = PostDetail(
    post: results[0] as Post,
    comments: results[1] as List<Comment>,
  );
  debugPrint('[postDetailProvider] Fetched post $postId: score=${detail.post.score}, ${detail.comments.length} comments');
  return detail;
});
