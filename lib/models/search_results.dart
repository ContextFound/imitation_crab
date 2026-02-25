import 'agent.dart';
import 'post.dart';
import 'submolt.dart';

class SearchResults {
  const SearchResults({
    required this.posts,
    required this.agents,
    required this.submolts,
    required this.totalPosts,
    required this.totalAgents,
    required this.totalSubmolts,
  });

  final List<Post> posts;
  final List<Agent> agents;
  final List<Submolt> submolts;
  final int totalPosts;
  final int totalAgents;
  final int totalSubmolts;

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    // API returns { results: [{ type: "agent"|"post"|"submolt", ... }] }
    final results = json['results'] as List<dynamic>? ?? [];
    final posts = <Post>[];
    final agents = <Agent>[];
    final submolts = <Submolt>[];

    for (final item in results) {
      final map = item as Map<String, dynamic>;
      final type = map['type'] as String?;
      switch (type) {
        case 'agent':
          agents.add(Agent.fromJson(_agentFromSearchResult(map)));
          break;
        case 'post':
          posts.add(Post.fromJson(map));
          break;
        case 'submolt':
          submolts.add(Submolt.fromJson(map));
          break;
      }
    }

    return SearchResults(
      posts: posts,
      agents: agents,
      submolts: submolts,
      totalPosts: (json['totalPosts'] as num?)?.toInt() ?? posts.length,
      totalAgents: (json['totalAgents'] as num?)?.toInt() ?? agents.length,
      totalSubmolts: (json['totalSubmolts'] as num?)?.toInt() ?? submolts.length,
    );
  }

  /// Converts search API agent format (author nested, title/content) to Agent model format.
  static Map<String, dynamic> _agentFromSearchResult(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final id = author?['id'] ?? json['id'];
    final name = author?['name'] ?? json['title'] ?? '';
    return {
      'id': id,
      'name': name,
      'displayName': json['title'],
      'description': json['content'],
      'karma': ((json['upvotes'] as num?)?.toInt() ?? 0) - ((json['downvotes'] as num?)?.toInt() ?? 0),
      'status': 'active',
      'isClaimed': true,
      'followerCount': 0,
      'followingCount': 0,
      'createdAt': json['created_at'] ?? json['createdAt'] ?? '',
    };
  }
}
