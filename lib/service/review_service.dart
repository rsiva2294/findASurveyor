
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service to manage the logic for prompting users for an in-app review.
/// It ensures that users are not prompted too frequently or after they have
/// already declined or completed a review.
class ReviewService {
  final InAppReview _inAppReview = InAppReview.instance;

  // These are the keys we will use to store our flags in SharedPreferences.
  static const String _lastPromptTimestampKey = 'last_review_prompt_timestamp';
  static const String _userDeclinedReviewKey = 'user_declined_review';

  /// The main method to be called from the UI after a successful user action.
  /// It checks all the rules before showing the custom review dialog.
  Future<void> requestReviewIfAppropriate(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // --- Rule 1: Check if the user has permanently declined before ---
    final bool hasDeclined = prefs.getBool(_userDeclinedReviewKey) ?? false;
    if (hasDeclined) {
      print("Review prompt skipped: User has permanently declined.");
      return;
    }

    // --- Rule 2: Check if it has been long enough since the last prompt ---
    final int? lastPromptTimestamp = prefs.getInt(_lastPromptTimestampKey);
    if (lastPromptTimestamp != null) {
      final lastPromptDate = DateTime.fromMillisecondsSinceEpoch(lastPromptTimestamp);
      // We set a 10-day waiting period before asking again.
      if (DateTime.now().difference(lastPromptDate).inDays < 10) {
        print("Review prompt skipped: Not enough time has passed since last prompt.");
        return;
      }
    }

    // If all checks pass, show our custom, polite dialog first.
    // We need the BuildContext to show the dialog.
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Enjoying our app?'),
          content: const Text('If you have a moment, please consider leaving a review. It helps us grow and improve.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _setRemindLater();
              },
              child: const Text('Remind Me Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _setPermanentlyDeclined();
              },
              child: const Text('No, Thanks'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchReviewFlow();
              },
              child: const Text('Rate Now'),
            ),
          ],
        ),
      );
    }
  }

  /// Launches the actual native review prompt (iOS/Android).
  Future<void> _launchReviewFlow() async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
      // After a successful request, we can consider it "declined" for future prompts
      // to avoid asking again, as we don't know if they actually rated.
      await _setPermanentlyDeclined();
    }
  }

  /// Updates the timestamp to reset the waiting period.
  Future<void> _setRemindLater() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPromptTimestampKey, DateTime.now().millisecondsSinceEpoch);
    print("User chose 'Remind Me Later'. Timestamp updated.");
  }

  /// Permanently disables future prompts.
  Future<void> _setPermanentlyDeclined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userDeclinedReviewKey, true);
    print("User declined review. Prompts will be disabled.");
  }
}