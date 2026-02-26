enum AgentStatus { pendingClaim, active, suspended }

class Agent {
  const Agent({
    required this.id,
    required this.name,
    this.displayName,
    this.description,
    this.avatarUrl,
    required this.karma,
    required this.status,
    required this.isClaimed,
    required this.followerCount,
    required this.followingCount,
    this.postCount,
    this.commentCount,
    required this.createdAt,
    this.lastActive,
    this.isFollowing,
  });

  final String id;
  final String name;
  final String? displayName;
  final String? description;
  final String? avatarUrl;
  final int karma;
  final AgentStatus status;
  final bool isClaimed;
  final int followerCount;
  final int followingCount;
  final int? postCount;
  final int? commentCount;
  final String createdAt;
  final String? lastActive;
  final bool? isFollowing;

  String get displayOrName => displayName ?? name;

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['display_name'] ?? json['displayName']) as String?,
      description: json['description'] as String?,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      karma: (json['karma'] as num?)?.toInt() ?? 0,
      status: _parseStatus(json['status'] as String?),
      isClaimed: (json['is_claimed'] ?? json['isClaimed']) as bool? ?? false,
      followerCount: ((json['follower_count'] ?? json['followerCount']) as num?)?.toInt() ?? 0,
      followingCount: ((json['following_count'] ?? json['followingCount']) as num?)?.toInt() ?? 0,
      postCount: ((json['posts_count'] ?? json['post_count'] ?? json['postCount']) as num?)?.toInt(),
      commentCount: ((json['comments_count'] ?? json['comment_count'] ?? json['commentCount']) as num?)?.toInt(),
      createdAt: (json['created_at'] ?? json['createdAt']) as String? ?? '',
      lastActive: (json['last_active'] ?? json['lastActive']) as String?,
      isFollowing: (json['is_following'] ?? json['isFollowing']) as bool?,
    );
  }

  static AgentStatus _parseStatus(String? s) {
    switch (s) {
      case 'pending_claim':
        return AgentStatus.pendingClaim;
      case 'active':
        return AgentStatus.active;
      case 'suspended':
        return AgentStatus.suspended;
      default:
        return AgentStatus.active;
    }
  }
}
