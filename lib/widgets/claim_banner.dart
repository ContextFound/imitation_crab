import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';

/// Persistent banner shown when the agent is registered but not yet claimed.
/// Displays the claim URL and a button to refresh claim status.
class ClaimBanner extends ConsumerStatefulWidget {
  const ClaimBanner({super.key});

  @override
  ConsumerState<ClaimBanner> createState() => _ClaimBannerState();
}

class _ClaimBannerState extends ConsumerState<ClaimBanner> {
  bool _checking = false;

  Future<void> _refreshStatus() async {
    setState(() => _checking = true);
    await ref.read(authStateProvider.notifier).refreshClaimStatus();
    if (mounted) {
      setState(() => _checking = false);
      final auth = ref.read(authStateProvider);
      if (!auth.needsClaim) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agent claimed successfully!')),
        );
      }
    }
  }

  Future<void> _openClaimUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (!auth.needsClaim) return const SizedBox.shrink();

    final claimUrl = auth.claimUrl;
    final theme = Theme.of(context);
    final amber = Colors.amber.shade800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.15),
        border: Border(bottom: BorderSide(color: amber.withValues(alpha: 0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Agent not yet claimed',
                  style: theme.textTheme.titleSmall?.copyWith(color: amber),
                ),
              ),
              if (_checking)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else
                TextButton.icon(
                  onPressed: _refreshStatus,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Check'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            claimUrl != null && claimUrl.isNotEmpty
                ? 'Visit the claim link to verify ownership. Until claimed, actions like voting are restricted.'
                : 'Tap Check to fetch your claim link. Until claimed, actions like voting are restricted.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (claimUrl != null && claimUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _openClaimUrl(claimUrl),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        claimUrl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
