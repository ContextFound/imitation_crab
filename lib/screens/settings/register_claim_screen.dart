import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';

class RegisterClaimScreen extends ConsumerStatefulWidget {
  const RegisterClaimScreen({super.key});

  @override
  ConsumerState<RegisterClaimScreen> createState() => _RegisterClaimScreenState();
}

class _RegisterClaimScreenState extends ConsumerState<RegisterClaimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _registerNameController = TextEditingController();
  final _registerDescController = TextEditingController();
  final _claimKeyController = TextEditingController();

  Map<String, dynamic>? _claimStatusResult;
  bool _claimCheckLoading = false;
  String? _claimTabError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _registerNameController.dispose();
    _registerDescController.dispose();
    _claimKeyController.dispose();
    super.dispose();
  }

  Future<void> _openClaimUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copied')),
      );
    }
  }

  Future<void> _checkClaimStatus() async {
    await ref.read(authStateProvider.notifier).refreshClaimStatus();
    if (!mounted) return;
    final auth = ref.read(authStateProvider);
    if (!auth.needsClaim) {
      ref.read(authStateProvider.notifier).clearRegistrationDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent claimed successfully!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (prev, next) {
      if (next.registrationDetails != null && prev?.registrationDetails == null) {
        setState(() {});
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Register / Claim Agent'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Register'),
            Tab(text: 'I have a token'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RegisterTab(
            nameController: _registerNameController,
            descController: _registerDescController,
            authState: authState,
            onRegister: () => ref.read(authStateProvider.notifier).register(
                  name: _registerNameController.text.trim(),
                  description: _registerDescController.text.trim().isEmpty
                      ? null
                      : _registerDescController.text.trim(),
                ),
            onOpenClaimUrl: _openClaimUrl,
            onCopy: _copy,
            onCheckStatus: _checkClaimStatus,
            onClearDetails: () => ref.read(authStateProvider.notifier).clearRegistrationDetails(),
          ),
          _ClaimTab(
            keyController: _claimKeyController,
            claimStatusResult: _claimStatusResult,
            loading: _claimCheckLoading,
            error: _claimTabError,
            onCheck: () async {
              setState(() {
                _claimTabError = null;
                _claimStatusResult = null;
                _claimCheckLoading = true;
              });
              final key = _claimKeyController.text.trim();
              try {
                await ref.read(authStateProvider.notifier).login(key);
                if (!mounted) return;
                final api = ref.read(moltbookApiProvider);
                final status = await api.getClaimStatus();
                if (!mounted) return;
                final statusStr = status['status'] as String?;
                if (statusStr == 'claimed') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Agent is claimed. You\'re all set.')),
                  );
                  context.pop();
                  return;
                }
                setState(() {
                  _claimStatusResult = status;
                  _claimCheckLoading = false;
                });
              } catch (e) {
                setState(() {
                  _claimTabError = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
                  _claimCheckLoading = false;
                });
              }
            },
            onOpenClaimUrl: _openClaimUrl,
            onCheckStatus: _checkClaimStatus,
          ),
        ],
      ),
    );
  }
}

class _RegisterTab extends StatelessWidget {
  const _RegisterTab({
    required this.nameController,
    required this.descController,
    required this.authState,
    required this.onRegister,
    required this.onOpenClaimUrl,
    required this.onCopy,
    required this.onCheckStatus,
    required this.onClearDetails,
  });

  final TextEditingController nameController;
  final TextEditingController descController;
  final AuthState authState;
  final VoidCallback onRegister;
  final void Function(String url) onOpenClaimUrl;
  final void Function(String text, String label) onCopy;
  final Future<void> Function() onCheckStatus;
  final VoidCallback onClearDetails;

  @override
  Widget build(BuildContext context) {
    final details = authState.registrationDetails;
    if (details != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agent registered. Complete claiming to use voting and other actions.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            _CopyableRow(label: 'API Key', value: details.apiKey, onCopy: () => onCopy(details.apiKey, 'API key')),
            if (details.claimUrl != null && details.claimUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _CopyableRow(label: 'Claim URL', value: details.claimUrl!, onCopy: () => onCopy(details.claimUrl!, 'Claim URL')),
            ],
            if (details.verificationCode != null && details.verificationCode!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _CopyableRow(
                label: 'Verification code',
                value: details.verificationCode!,
                onCopy: () => onCopy(details.verificationCode!, 'Verification code'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => details.claimUrl != null && details.claimUrl!.isNotEmpty
                  ? onOpenClaimUrl(details.claimUrl!)
                  : null,
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: const Text('Open Claim Link'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: authState.isLoading ? null : onCheckStatus,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Check Status'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClearDetails,
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (authState.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(child: SelectableText(authState.error!)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Agent Name',
              hintText: 'my_research_agent',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'What you do',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: authState.isLoading ? null : onRegister,
            child: authState.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Register'),
          ),
          const SizedBox(height: 12),
          Text(
            'You will receive an API key and a claim URL. Save the key securely—it cannot be recovered.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ClaimTab extends StatelessWidget {
  const _ClaimTab({
    required this.keyController,
    required this.claimStatusResult,
    required this.loading,
    required this.error,
    required this.onCheck,
    required this.onOpenClaimUrl,
    required this.onCheckStatus,
  });

  final TextEditingController keyController;
  final Map<String, dynamic>? claimStatusResult;
  final bool loading;
  final String? error;
  final VoidCallback onCheck;
  final void Function(String url) onOpenClaimUrl;
  final Future<void> Function() onCheckStatus;

  @override
  Widget build(BuildContext context) {
    final status = claimStatusResult?['status'] as String?;
    final claimUrl = claimStatusResult?['claim_url'] as String?;
    final agent = claimStatusResult?['agent'];
    final agentName = agent is Map ? agent['name'] as String? : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter your existing API key to see the claim link and complete claiming.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: keyController,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'moltbook_xxx',
            ),
            obscureText: true,
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loading ? null : onCheck,
            child: loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Check status'),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(error!),
            ),
          ],
          if (status == 'pending_claim' && claimUrl != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            Text(
              agentName != null ? 'Claim agent "$agentName"' : 'Claim your agent',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => onOpenClaimUrl(claimUrl),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        claimUrl,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: loading ? null : onCheckStatus,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Check Status'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyableRow extends StatelessWidget {
  const _CopyableRow({required this.label, required this.value, required this.onCopy});

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.copy), onPressed: onCopy, tooltip: 'Copy'),
          ],
        ),
      ],
    );
  }
}
