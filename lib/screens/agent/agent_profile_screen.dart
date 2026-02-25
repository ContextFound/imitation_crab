import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/agent.dart';
import '../../models/post.dart';
import '../../providers/agent_provider.dart';
import '../../widgets/follow_button.dart';
import '../../widgets/post_card.dart';

class AgentProfileScreen extends ConsumerWidget {
  const AgentProfileScreen({super.key, required this.agentName});

  final String agentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(agentProfileProvider(agentName));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('u/$agentName'),
      ),
      body: profileAsync.when(
        data: (data) {
          final agentJson = data['agent'];
          final recentPosts = data['recentPosts'] as List<dynamic>? ?? [];
          if (agentJson == null) return const Center(child: Text('Agent not found'));
          final agent = Agent.fromJson(agentJson as Map<String, dynamic>);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      child: Text(
                        (agent.displayOrName.isNotEmpty ? agent.displayOrName[0] : '?').toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(agent.displayOrName, style: Theme.of(context).textTheme.titleLarge),
                          Text('${agent.karma} karma', style: Theme.of(context).textTheme.bodyMedium),
                          Text('${agent.followerCount} followers', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    FollowButton(agentName: agent.name, isFollowing: agent.isFollowing ?? false),
                  ],
                ),
                if (agent.description != null && agent.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(agent.description!),
                ],
                const SizedBox(height: 24),
                Text('Recent posts', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...recentPosts.map((p) => PostCard(post: Post.fromJson(p as Map<String, dynamic>))),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: SelectableText('Error: $e')),
      ),
    );
  }
}
