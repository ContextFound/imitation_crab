import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/api_debug_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/api_debug_dialog.dart';
import '../../widgets/post_card.dart';

enum _SearchMode { text, post }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  _SearchMode _mode = _SearchMode.text;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final q = value.trim();
    if (q.isEmpty) return;

    if (_mode == _SearchMode.post) {
      _lookupPost(q);
    } else {
      setState(() => _query = q);
    }
  }

  Future<void> _lookupPost(String postId) async {
    setState(() => _query = postId);
    try {
      await ref.read(postProvider(postId).future);
      if (mounted) context.push('/post/$postId');
    } catch (_) {
      // State already set — the body will show "No post found"
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: _mode == _SearchMode.text ? 'Search...' : 'Post number...',
          ),
          onSubmitted: _submit,
        ),
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
            icon: const Icon(Icons.search),
            onPressed: () => _submit(_controller.text),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<_SearchMode>(
              segments: const [
                ButtonSegment(value: _SearchMode.text, label: Text('Text'), icon: Icon(Icons.text_fields)),
                ButtonSegment(value: _SearchMode.post, label: Text('Post'), icon: Icon(Icons.tag)),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => setState(() {
                _mode = selection.first;
                _query = '';
              }),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_query.isEmpty) {
      return Center(
        child: Text(_mode == _SearchMode.text ? 'Enter a search query' : 'Enter a post number'),
      );
    }

    if (_mode == _SearchMode.post) {
      final postAsync = ref.watch(postProvider(_query));
      return postAsync.when(
        data: (_) => const SizedBox.shrink(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Padding(padding: EdgeInsets.all(48), child: Text('No post found')),
        ),
      );
    }

    final searchAsync = ref.watch(searchResultsProvider(_query));
    return searchAsync.when(
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
    );
  }
}
