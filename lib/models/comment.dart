import 'post.dart';

enum CommentSort { top, new_, controversial }

class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.content,
    required this.score,
    required this.upvotes,
    required this.downvotes,
    this.parentId,
    required this.depth,
    required this.authorId,
    required this.authorName,
    this.authorDisplayName,
    this.authorAvatarUrl,
    this.userVote,
    required this.createdAt,
    this.editedAt,
    this.isCollapsed,
    this.replies = const [],
    this.replyCount,
  });

  final String id;
  final String postId;
  final String content;
  final int score;
  final int upvotes;
  final int downvotes;
  final String? parentId;
  final int depth;
  final String authorId;
  final String authorName;
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final VoteDirection? userVote;
  final String createdAt;
  final String? editedAt;
  final bool? isCollapsed;
  final List<Comment> replies;
  final int? replyCount;

  String get authorDisplayOrName => authorDisplayName ?? authorName;

  factory Comment.fromJson(Map<String, dynamic> json) {
    final repliesJson = json['replies'] as List<dynamic>?;
    final postId = json['postId'] as String? ?? json['post_id'] as String? ?? '';
    final authorId = json['authorId'] as String? ?? json['author_id'] as String? ?? '';
    final authorObj = json['author'] as Map<String, dynamic>?;
    final authorName = authorObj?['name'] as String? ?? json['authorName'] as String? ?? '';
    final authorDisplayName = authorObj?['displayName'] as String? ?? authorObj?['description'] as String? ?? json['authorDisplayName'] as String?;
    final authorAvatarUrl = authorObj?['avatarUrl'] as String? ?? json['authorAvatarUrl'] as String?;
    final createdAt = json['createdAt'] as String? ?? json['created_at'] as String? ?? '';
    final editedAt = json['editedAt'] as String? ?? json['updated_at'] as String?;
    final replyCountVal = json['replyCount'] ?? json['reply_count'];
    final replyCount = replyCountVal is num ? replyCountVal.toInt() : (replyCountVal is String ? int.tryParse(replyCountVal) : null);

    return Comment(
      id: json['id'] as String,
      postId: postId,
      content: json['content'] as String,
      score: (json['score'] as num?)?.toInt() ?? 0,
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
      parentId: json['parentId'] as String? ?? json['parent_id'] as String?,
      depth: (json['depth'] as num?)?.toInt() ?? 0,
      authorId: authorId,
      authorName: authorName,
      authorDisplayName: authorDisplayName,
      authorAvatarUrl: authorAvatarUrl,
      userVote: Post.parseVote(json['userVote'] ?? json['user_vote']),
      createdAt: createdAt,
      editedAt: editedAt,
      isCollapsed: json['isCollapsed'] as bool? ?? json['is_collapsed'] as bool?,
      replies: repliesJson != null
          ? repliesJson
              .map((e) => Comment.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      replyCount: replyCount,
    );
  }
}
