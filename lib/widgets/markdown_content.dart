import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reusable widget that renders markdown content with Material theming
/// and link handling via url_launcher.
class MarkdownContent extends StatelessWidget {
  const MarkdownContent({
    super.key,
    required this.data,
    this.maxLines,
  });

  /// The markdown string to render.
  final String data;

  /// Optional max height to approximate line truncation (e.g. 3 lines ~ 72px).
  /// When provided, content is clipped; otherwise full content is shown.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (data.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final body = MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(theme),
      onTapLink: (text, href, title) {
        if (href != null && href.isNotEmpty) {
          final uri = Uri.tryParse(href);
          if (uri != null) {
            launchUrl(uri);
          }
        }
      },
    );

    if (maxLines != null) {
      // ~28px per line for body text; use SingleChildScrollView
      // to clip overflow without triggering layout overflow errors.
      final maxHeight = (maxLines! * 28.0).clamp(28.0, double.infinity);
      return SizedBox(
        height: maxHeight,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          clipBehavior: Clip.hardEdge,
          child: body,
        ),
      );
    }

    return body;
  }
}
