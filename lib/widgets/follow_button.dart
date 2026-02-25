import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/agent_provider.dart';
import '../providers/auth_provider.dart';

class FollowButton extends ConsumerStatefulWidget {
  const FollowButton({super.key, required this.agentName, required this.isFollowing});

  final String agentName;
  final bool isFollowing;

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _isLoading ? null : () async {
        setState(() => _isLoading = true);
        try {
          final api = ref.read(moltbookApiProvider);
          if (widget.isFollowing) {
            await api.unfollowAgent(widget.agentName);
          } else {
            await api.followAgent(widget.agentName);
          }
          ref.invalidate(agentProfileProvider(widget.agentName));
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(widget.isFollowing ? 'Unfollow' : 'Follow'),
    );
  }
}
