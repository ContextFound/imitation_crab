import '../../models/agent.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../models/search_results.dart';
import '../../models/submolt.dart';
import 'moltbook_client.dart';

class MoltbookApi {
  MoltbookApi({required this.client});

  final MoltbookClient client;

  // --- Agent ---

  Future<Map<String, dynamic>> registerAgent({required String name, String? description}) async {
    final res = await client.post<Map<String, dynamic>>('/agents/register', data: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return res;
  }

  Future<Agent> getMe() async {
    final res = await client.get<Map<String, dynamic>>('/agents/me');
    return Agent.fromJson(res['agent'] as Map<String, dynamic>);
  }

  Future<Agent> updateMe({String? displayName, String? description}) async {
    final res = await client.patch<Map<String, dynamic>>('/agents/me', data: {
      if (displayName != null) 'displayName': displayName,
      if (description != null) 'description': description,
    });
    return Agent.fromJson(res['agent'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getAgentProfile(String name) async {
    return client.get<Map<String, dynamic>>('/agents/profile', queryParameters: {'name': name});
  }

  Future<void> followAgent(String name) async {
    await client.post<Map<String, dynamic>>('/agents/$name/follow');
  }

  Future<void> unfollowAgent(String name) async {
    await client.delete<Map<String, dynamic>>('/agents/$name/follow');
  }

  // --- Posts ---

  Future<Map<String, dynamic>> getPosts({
    PostSort sort = PostSort.hot,
    int limit = 25,
    int offset = 0,
    String? submolt,
    String? t,
  }) async {
    final params = <String, dynamic>{
      'sort': _postSortToString(sort),
      'limit': limit,
      'offset': offset,
    };
    if (submolt != null && submolt.isNotEmpty) params['submolt'] = submolt;
    if (t != null && t.isNotEmpty) params['t'] = t;
    return client.get<Map<String, dynamic>>('/posts', queryParameters: params);
  }

  Future<Post> getPost(String id) async {
    final res = await client.get<Map<String, dynamic>>('/posts/$id');
    return Post.fromJson(res['post'] as Map<String, dynamic>);
  }

  Future<Post> createPost({
    required String submolt,
    required String title,
    String? content,
    String? url,
    PostType postType = PostType.text,
  }) async {
    final data = <String, dynamic>{
      'submolt': submolt,
      'title': title,
      'postType': postType == PostType.link ? 'link' : 'text',
    };
    if (content != null && content.isNotEmpty) data['content'] = content;
    if (url != null && url.isNotEmpty) data['url'] = url;
    final res = await client.post<Map<String, dynamic>>('/posts', data: data);
    return Post.fromJson(res['post'] as Map<String, dynamic>);
  }

  Future<void> deletePost(String id) async {
    await client.delete<Map<String, dynamic>>('/posts/$id');
  }

  Future<Map<String, dynamic>> upvotePost(String id) async {
    return client.post<Map<String, dynamic>>('/posts/$id/upvote');
  }

  Future<Map<String, dynamic>> downvotePost(String id) async {
    return client.post<Map<String, dynamic>>('/posts/$id/downvote');
  }

  // --- Comments ---

  Future<List<Comment>> getComments(
    String postId, {
    CommentSort sort = CommentSort.top,
    int limit = 100,
  }) async {
    final res = await client.get<Map<String, dynamic>>(
      '/posts/$postId/comments',
      queryParameters: {'sort': _commentSortToString(sort), 'limit': limit},
    );
    final list = res['comments'] as List<dynamic>? ?? [];
    return list.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Comment> createComment(String postId, {required String content, String? parentId}) async {
    final data = <String, dynamic>{'content': content};
    if (parentId != null && parentId.isNotEmpty) data['parent_id'] = parentId;
    final res = await client.post<Map<String, dynamic>>('/posts/$postId/comments', data: data);
    return Comment.fromJson(res['comment'] as Map<String, dynamic>);
  }

  Future<void> deleteComment(String id) async {
    await client.delete<Map<String, dynamic>>('/comments/$id');
  }

  Future<Map<String, dynamic>> upvoteComment(String id) async {
    return client.post<Map<String, dynamic>>('/comments/$id/upvote');
  }

  Future<Map<String, dynamic>> downvoteComment(String id) async {
    return client.post<Map<String, dynamic>>('/comments/$id/downvote');
  }

  // --- Submolts ---

  Future<Map<String, dynamic>> getSubmolts({
    required SubmoltListSort sort,
    int limit = 50,
    int offset = 0,
  }) async {
    return client.get<Map<String, dynamic>>(
      '/submolts',
      queryParameters: {'sort': sort.apiValue, 'limit': limit, 'offset': offset},
    );
  }

  Future<Submolt> getSubmolt(String name) async {
    final res = await client.get<Map<String, dynamic>>('/submolts/$name');
    return Submolt.fromJson(res['submolt'] as Map<String, dynamic>);
  }

  Future<Submolt> createSubmolt({required String name, String? displayName, String? description}) async {
    final data = <String, dynamic>{'name': name};
    if (displayName != null && displayName.isNotEmpty) data['display_name'] = displayName;
    if (description != null && description.isNotEmpty) data['description'] = description;
    final res = await client.post<Map<String, dynamic>>('/submolts', data: data);
    return Submolt.fromJson(res['submolt'] as Map<String, dynamic>);
  }

  Future<void> subscribeSubmolt(String name) async {
    await client.post<Map<String, dynamic>>('/submolts/$name/subscribe');
  }

  Future<void> unsubscribeSubmolt(String name) async {
    await client.delete<Map<String, dynamic>>('/submolts/$name/subscribe');
  }

  Future<Map<String, dynamic>> getSubmoltFeed(
    String name, {
    PostSort sort = PostSort.hot,
    int limit = 25,
    int offset = 0,
  }) async {
    return client.get<Map<String, dynamic>>(
      '/submolts/$name/feed',
      queryParameters: {'sort': _postSortToString(sort), 'limit': limit, 'offset': offset},
    );
  }

  // --- Feed ---

  Future<Map<String, dynamic>> getFeed({
    PostSort sort = PostSort.hot,
    int limit = 25,
    int offset = 0,
  }) async {
    return client.get<Map<String, dynamic>>(
      '/feed',
      queryParameters: {'sort': _postSortToString(sort), 'limit': limit, 'offset': offset},
    );
  }

  // --- Search ---

  Future<SearchResults> search(String query, {int limit = 25}) async {
    final res = await client.get<Map<String, dynamic>>('/search', queryParameters: {'q': query, 'limit': limit});
    return SearchResults.fromJson(res);
  }

  static String _postSortToString(PostSort s) {
    switch (s) {
      case PostSort.hot:
        return 'hot';
      case PostSort.new_:
        return 'new';
      case PostSort.top:
        return 'top';
      case PostSort.rising:
        return 'rising';
    }
  }

  static String _commentSortToString(CommentSort s) {
    switch (s) {
      case CommentSort.top:
        return 'top';
      case CommentSort.new_:
        return 'new';
      case CommentSort.controversial:
        return 'controversial';
    }
  }
}
