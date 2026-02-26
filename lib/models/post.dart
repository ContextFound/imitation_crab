enum PostType { text, link }

enum PostSort { random, new_, top, discussed }

/// Whether a sort mode uses a time period filter.
extension PostSortX on PostSort {
  bool get hasTimePeriod => this == PostSort.top || this == PostSort.discussed;
}

/// Time period for feed. API doesn't support t, so we filter client-side.
enum FeedTimePeriod {
  all('', 'All time'),
  hour('hour', 'Past hour'),
  day('day', 'Today'),
  week('week', 'This week');

  const FeedTimePeriod(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

enum VoteDirection { up, down }

class Post {
  const Post({
    required this.id,
    required this.title,
    this.content,
    this.url,
    required this.submolt,
    this.submoltDisplayName,
    required this.postType,
    required this.score,
    this.upvotes,
    this.downvotes,
    required this.commentCount,
    required this.authorId,
    required this.authorName,
    this.authorDisplayName,
    this.authorAvatarUrl,
    this.userVote,
    this.isSaved,
    this.isHidden,
    required this.createdAt,
    this.editedAt,
  });

  final String id;
  final String title;
  final String? content;
  final String? url;
  final String submolt;
  final String? submoltDisplayName;
  final PostType postType;
  final int score;
  final int? upvotes;
  final int? downvotes;
  final int commentCount;
  final String authorId;
  final String authorName;
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final VoteDirection? userVote;
  final bool? isSaved;
  final bool? isHidden;
  final String createdAt;
  final String? editedAt;

  String get authorDisplayOrName => authorDisplayName ?? authorName;

  factory Post.fromJson(Map<String, dynamic> json) {
    final submoltRaw = json['submolt'];
    final submoltNameRaw = json['submolt_name'];
    final String submolt;
    final String? submoltDisplayName;
    if (submoltRaw is Map<String, dynamic>) {
      submolt = (submoltRaw['name'] ?? submoltRaw['id'] ?? '') as String;
      submoltDisplayName = submoltRaw['display_name'] as String?;
    } else if (submoltNameRaw != null) {
      submolt = submoltNameRaw as String;
      submoltDisplayName = json['submoltDisplayName'] as String?;
    } else {
      submolt = (submoltRaw as String?) ?? '';
      submoltDisplayName = json['submoltDisplayName'] as String?;
    }

    final authorRaw = json['author'];
    final String authorId;
    final String authorName;
    final String? authorAvatarUrl;
    if (authorRaw is Map<String, dynamic>) {
      final name = authorRaw['name'] ?? json['authorName'];
      authorId = (authorRaw['id'] ?? json['author_id'] ?? name ?? '') as String;
      authorName = (name as String?) ?? json['authorName'] as String? ?? '';
      authorAvatarUrl = authorRaw['avatarUrl'] as String? ?? authorRaw['avatar_url'] as String?;
    } else {
      authorId = json['authorId'] as String? ?? json['author_id'] as String? ?? '';
      authorName = json['authorName'] as String? ?? '';
      authorAvatarUrl = json['authorAvatarUrl'] as String?;
    }

    final postTypeRaw = json['postType'] ?? json['type'];
    final postType = postTypeRaw == 'link' ? PostType.link : PostType.text;

    final commentCountRaw = json['commentCount'] ?? json['comment_count'];
    final commentCount = (commentCountRaw as num?)?.toInt() ?? 0;

    final scoreRaw = json['score'] as num?;
    final upvotesRaw = (json['upvotes'] as num?)?.toInt();
    final downvotesRaw = (json['downvotes'] as num?)?.toInt();
    final score = scoreRaw != null
        ? scoreRaw.toInt()
        : ((upvotesRaw ?? 0) - (downvotesRaw ?? 0));

    final createdAtRaw = json['createdAt'] ?? json['created_at'];
    final createdAt = createdAtRaw as String? ?? '';
    final editedAt = json['editedAt'] as String? ?? json['updated_at'] as String?;

    return Post(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      url: json['url'] as String?,
      submolt: submolt,
      submoltDisplayName: submoltDisplayName,
      postType: postType,
      score: score,
      upvotes: upvotesRaw,
      downvotes: downvotesRaw,
      commentCount: commentCount,
      authorId: authorId,
      authorName: authorName,
      authorDisplayName: json['authorDisplayName'] as String?,
      authorAvatarUrl: authorAvatarUrl,
      userVote: parseVote(json['userVote']),
      isSaved: json['isSaved'] as bool?,
      isHidden: json['isHidden'] as bool?,
      createdAt: createdAt,
      editedAt: editedAt,
    );
  }

  static VoteDirection? parseVote(dynamic v) {
    if (v == null) return null;
    if (v == 'up') return VoteDirection.up;
    if (v == 'down') return VoteDirection.down;
    return null;
  }
}
