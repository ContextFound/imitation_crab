import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/submolt_provider.dart';

class SubmoltsScreen extends ConsumerWidget {
  const SubmoltsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submoltsAsync = ref.watch(submoltsListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Submolts'),
      ),
      body: submoltsAsync.when(
        data: (submolts) => submolts.isEmpty
            ? const Center(child: Text('No submolts yet'))
            : ListView.builder(
                itemCount: submolts.length,
                itemBuilder: (context, i) {
                  final s = submolts[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.group)),
                    title: Text('m/${s.displayOrName}'),
                    subtitle: s.description != null ? Text(s.description!, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                    trailing: Text('${s.subscriberCount}'),
                    onTap: () => context.push('/m/${s.name}'),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: SelectableText('Error: $e')),
      ),
    );
  }
}
