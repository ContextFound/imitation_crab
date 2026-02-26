import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/api_exceptions.dart';
import '../core/api/moltbook_api.dart';

/// Calls a vote API endpoint directly and handles errors with user feedback.
/// Returns true if the vote succeeded, false otherwise.
///
/// If [claimUrl] is provided, it will be used in the "Open Claim Link" action
/// when the agent is not yet claimed. Otherwise no action is shown.
Future<bool> handleVote(
  BuildContext context,
  Future<void> Function() performVote, {
  String? claimUrl,
}) async {
  debugPrint('[handleVote] Starting vote call...');
  try {
    await performVote();
    debugPrint('[handleVote] Vote succeeded');
    return true;
  } on DioException catch (e) {
    debugPrint('[handleVote] DioException: ${e.error}');
    final apiEx = e.error;
    if (apiEx is ApiException && context.mounted) {
      final msg = apiEx.message;
      final isClaimRequired = apiEx.statusCode == 403 && msg.toLowerCase().contains('claimed agent');
      final hasClaimUrl = claimUrl != null && claimUrl.isNotEmpty;
      debugPrint('[handleVote] Showing SnackBar: $msg (claimRequired=$isClaimRequired)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: isClaimRequired ? const Duration(seconds: 6) : const Duration(seconds: 4),
          action: isClaimRequired && hasClaimUrl
              ? SnackBarAction(
                  label: 'Open Claim Link',
                  onPressed: () => launchUrl(
                    Uri.parse(claimUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                )
              : null,
        ),
      );
    }
    return false;
  } catch (e) {
    debugPrint('[handleVote] Unexpected error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote failed: $e')),
      );
    }
    return false;
  }
}

/// Upvote or downvote a post directly via the API (no provider caching).
Future<bool> votePost(BuildContext context, MoltbookApi api, String postId, {required bool isUpvote, String? claimUrl}) {
  debugPrint('[votePost] ${isUpvote ? "Upvote" : "Downvote"} for post $postId');
  return handleVote(
    context,
    () => isUpvote ? api.upvotePost(postId) : api.downvotePost(postId),
    claimUrl: claimUrl,
  );
}

/// Upvote or downvote a comment directly via the API (no provider caching).
Future<bool> voteComment(BuildContext context, MoltbookApi api, String commentId, {required bool isUpvote, String? claimUrl}) {
  debugPrint('[voteComment] ${isUpvote ? "Upvote" : "Downvote"} for comment $commentId');
  return handleVote(
    context,
    () => isUpvote ? api.upvoteComment(commentId) : api.downvoteComment(commentId),
    claimUrl: claimUrl,
  );
}
