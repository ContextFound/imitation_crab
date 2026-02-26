import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/auth_provider.dart';

class RegistrationSuccessDialog extends StatelessWidget {
  const RegistrationSuccessDialog({
    super.key,
    required this.details,
    required this.onClose,
  });

  final RegistrationDetails details;
  final VoidCallback onClose;

  Future<void> _copyToClipboard(BuildContext context, String label, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agent Registered Successfully'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CopyableField(
              label: 'Agent Name',
              value: details.name,
              onCopy: () => _copyToClipboard(context, 'Agent name', details.name),
            ),
            const SizedBox(height: 16),
            _CopyableField(
              label: 'Description',
              value: details.description.isEmpty ? '(none)' : details.description,
              onCopy: () => _copyToClipboard(context, 'Description', details.description),
            ),
            const SizedBox(height: 16),
            _CopyableField(
              label: 'API Key',
              value: details.apiKey,
              onCopy: () => _copyToClipboard(context, 'API key', details.apiKey),
            ),
            if (details.claimUrl != null && details.claimUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _CopyableField(
                label: 'Claim URL',
                value: details.claimUrl!,
                onCopy: () => _copyToClipboard(context, 'Claim URL', details.claimUrl!),
              ),
            ],
            if (details.verificationCode != null && details.verificationCode!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _CopyableField(
                label: 'Verification code',
                value: details.verificationCode!,
                onCopy: () => _copyToClipboard(context, 'Verification code', details.verificationCode!),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will need this API key in the future. Store it in a safe place—it cannot be recovered.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: onClose,
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _CopyableField extends StatelessWidget {
  const _CopyableField({
    required this.label,
    required this.value,
    required this.onCopy,
  });

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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: onCopy,
              tooltip: 'Copy to clipboard',
            ),
          ],
        ),
      ],
    );
  }
}
