import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/post.dart';
import '../../providers/api_debug_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/submolt_provider.dart';
import '../../widgets/api_debug_dialog.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  PostType _postType = PostType.text;
  final _submoltController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _submoltController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final submolt = _submoltController.text.trim();
    final title = _titleController.text.trim();
    if (submolt.isEmpty || title.isEmpty) {
      setState(() => _error = 'Submolt and title are required');
      return;
    }
    if (_postType == PostType.text) {
      final content = _contentController.text.trim();
      if (content.isEmpty) {
        setState(() => _error = 'Content is required for text posts');
        return;
      }
    } else {
      final url = _urlController.text.trim();
      if (url.isEmpty) {
        setState(() => _error = 'URL is required for link posts');
        return;
      }
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final api = ref.read(moltbookApiProvider);
      await api.createPost(
        submolt: submolt,
        title: title,
        content: _postType == PostType.text ? _contentController.text.trim() : null,
        url: _postType == PostType.link ? _urlController.text.trim() : null,
        postType: _postType,
      );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final submoltsAsync = ref.watch(submoltsListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: const Text('Create Post'),
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
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Post'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _submoltController,
              decoration: const InputDecoration(
                labelText: 'Submolt',
                hintText: 'general',
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<PostType>(
              segments: const [
                ButtonSegment(value: PostType.text, label: Text('Text')),
                ButtonSegment(value: PostType.link, label: Text('Link')),
              ],
              selected: {_postType},
              onSelectionChanged: (s) => setState(() => _postType = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            if (_postType == PostType.text)
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 6,
              ),
            if (_postType == PostType.link)
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL', hintText: 'https://...'),
                keyboardType: TextInputType.url,
              ),
            const SizedBox(height: 24),
            submoltsAsync.when(
              data: (submolts) {
                if (submolts.isEmpty) return const SizedBox.shrink();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: submolts.take(10).map((s) {
                    return ActionChip(
                      label: Text('m/${s.name}'),
                      onPressed: () => _submoltController.text = s.name,
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
