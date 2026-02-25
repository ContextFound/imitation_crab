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
