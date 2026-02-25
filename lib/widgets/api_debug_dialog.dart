import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/debug/api_debug.dart';

class ApiDebugDialog extends StatelessWidget {
  const ApiDebugDialog({super.key, required this.record});

  final ApiCallRecord record;

  String _formatBody(dynamic body) {
    if (body == null) return '';
    if (body is String) {
      try {
        final decoded = jsonDecode(body);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return body;
      }
    }
    return const JsonEncoder.withIndent('  ').convert(body);
  }

  String get _fullText {
    final buffer = StringBuffer();
    buffer.writeln('=== REQUEST ===');
    buffer.writeln('${record.method} ${record.url}');
    buffer.writeln();
    buffer.writeln('Headers:');
    for (final e in record.requestHeaders.entries) {
      buffer.writeln('  ${e.key}: ${e.value}');
    }
    if (record.requestBody != null) {
      buffer.writeln();
      buffer.writeln('Body:');
      buffer.writeln(_formatBody(record.requestBody));
    }
    buffer.writeln();
    buffer.writeln('=== RESPONSE ===');
    buffer.writeln('Status: ${record.responseStatus ?? "N/A"}');
    if (record.error != null) {
      buffer.writeln('Error: ${record.error}');
    }
    if (record.responseHeaders != null && record.responseHeaders!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Headers:');
      for (final e in record.responseHeaders!.entries) {
        buffer.writeln('  ${e.key}: ${e.value.join(", ")}');
      }
    }
    if (record.responseBody != null) {
      buffer.writeln();
      buffer.writeln('Body:');
      buffer.writeln(_formatBody(record.responseBody));
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Latest API Call',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy to clipboard',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _fullText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _fullText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
