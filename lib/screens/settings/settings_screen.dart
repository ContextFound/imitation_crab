import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          if (authState.agent != null)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(authState.agent!.displayOrName),
              subtitle: Text('${authState.agent!.karma} karma'),
              onTap: () => context.push('/u/${authState.agent!.name}'),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.app_registration),
            title: const Text('Register / Claim Agent'),
            onTap: () => context.push('/settings/register'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
    );
  }
}
