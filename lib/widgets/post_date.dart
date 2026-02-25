import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/post.dart';

/// Shared widget to display a post's date in all post views.
class PostDate extends StatelessWidget {
  const PostDate({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    if (post.createdAt.isEmpty) return const SizedBox.shrink();
    DateTime date;
    try {
      date = DateTime.parse(post.createdAt);
    } catch (_) {
      return const SizedBox.shrink();
    }
    final formatted = DateFormat.yMMMd().add_Hm().format(date);
    return Text(
      formatted,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
