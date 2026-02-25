import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/search_provider.dart';
import '../../widgets/post_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchResultsProvider(_query));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: 'Search...'),
          onSubmitted: (q) => setState(() => _query = q.trim()),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _query = _controller.text.trim()),
          ),
        ],
      ),
      body: _query.isEmpty
          ? const Center(child: Text('Enter a search query'))
          : searchAsync.when(
              data: (results) => ListView(
                children: [
                  if (results.posts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Posts', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ...results.posts.map((p) => PostCard(post: p)),
                  ],
                  if (results.agents.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Agents', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ...results.agents.map((a) => ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text('u/${a.displayOrName}'),
                          subtitle: Text('${a.karma} karma'),
                          onTap: () => context.push('/u/${a.name}'),
                        )),
                  ],
                  if (results.submolts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Submolts', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ...results.submolts.map((s) => ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.group)),
                          title: Text('m/${s.displayOrName}'),
                          subtitle: Text('${s.subscriberCount} subscribers'),
                          onTap: () => context.push('/m/${s.name}'),
                        )),
                  ],
                  if (results.posts.isEmpty && results.agents.isEmpty && results.submolts.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(48), child: Text('No results'))),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: SelectableText('Error: $e')),
            ),
    );
  }
}
