import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/api_exceptions.dart';

/// Handles vote API calls with user-friendly error feedback.
/// Returns true if the vote succeeded, false otherwise.
///
/// If [claimUrl] is provided, it will be used in the "Claim" action when the
/// agent is not yet claimed. Otherwise falls back to the generic claim page.
Future<bool> handleVote(
  BuildContext context,
  Future<void> Function() performVote, {
  String? claimUrl,
}) async {
  try {
    await performVote();
    return true;
  } on DioException catch (e) {
    final apiEx = e.error;
    if (apiEx is ApiException && context.mounted) {
      final msg = apiEx.message;
      final isClaimRequired = apiEx.statusCode == 403 && msg.toLowerCase().contains('claimed agent');
      final targetUrl = claimUrl ?? 'https://www.moltbook.com/claim';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: isClaimRequired ? const Duration(seconds: 6) : const Duration(seconds: 4),
          action: isClaimRequired
              ? SnackBarAction(
                  label: 'Open Claim Link',
                  onPressed: () => launchUrl(
                    Uri.parse(targetUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                )
              : null,
        ),
      );
    }
    return false;
  }
}
