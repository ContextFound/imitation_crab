import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/submolt.dart';
import '../../providers/api_debug_provider.dart';
import '../../providers/submolt_provider.dart';
import '../../widgets/api_debug_dialog.dart';

class SubmoltsScreen extends ConsumerStatefulWidget {
  const SubmoltsScreen({super.key});

  @override
  ConsumerState<SubmoltsScreen> createState() => _SubmoltsScreenState();
}

class _SubmoltsScreenState extends ConsumerState<SubmoltsScreen> {
  SubmoltListSort _sort = SubmoltListSort.popular;

  static const Map<SubmoltListSort, String> _sortLabels = {
    SubmoltListSort.popular: 'Popular',
    SubmoltListSort.new_: 'New',
    SubmoltListSort.top: 'Top',
  };

  @override
  Widget build(BuildContext context) {
    final submoltsAsync = ref.watch(submoltsListProvider(_sort));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Submolts'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'API Debug',
              onPressed: () {
                final record = ref.read(apiDebugNotifierProvider).latest;
                if (record == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No API calls recorded yet')),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => ApiDebugDialog(record: record),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(submoltsListProvider(_sort)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final s in SubmoltListSort.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_sortLabels[s]!),
                        selected: _sort == s,
                        onSelected: (_) {
                          ref.invalidate(submoltsListProvider(s));
                          setState(() => _sort = s);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: submoltsAsync.when(
        data: (submolts) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(submoltsListProvider(_sort)),
          child: submolts.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 48),
                    const Center(child: Text('No submolts yet')),
                  ],
                )
              : ListView.builder(
                  itemCount: submolts.length,
                  itemBuilder: (context, i) {
                    final s = submolts[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.group)),
                      title: Text('m/${s.displayOrName}'),
                      subtitle: s.description != null
                          ? Text(s.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
                          : null,
                      trailing: Text('${s.subscriberCount}'),
                      onTap: () => context.push('/m/${s.name}'),
                    );
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SelectableText('Error: $e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(submoltsListProvider(_sort)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
