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
    final postsJson = json['posts'] as List<dynamic>? ?? [];
    final agentsJson = json['agents'] as List<dynamic>? ?? [];
    final submoltsJson = json['submolts'] as List<dynamic>? ?? [];
    return SearchResults(
      posts: postsJson.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList(),
      agents: agentsJson.map((e) => Agent.fromJson(e as Map<String, dynamic>)).toList(),
      submolts: submoltsJson.map((e) => Submolt.fromJson(e as Map<String, dynamic>)).toList(),
      totalPosts: (json['totalPosts'] as num?)?.toInt() ?? 0,
      totalAgents: (json['totalAgents'] as num?)?.toInt() ?? 0,
      totalSubmolts: (json['totalSubmolts'] as num?)?.toInt() ?? 0,
    );
  }
}
