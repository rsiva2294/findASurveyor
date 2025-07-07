
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// A service to manage the logic for prompting users for an in-app review.
/// It ensures that users are not prompted too frequently or after they have
/// already declined or completed a review.
class ReviewService {
  final InAppReview _inAppReview = InAppReview.instance;

  static const String _lastPromptTimestampKey = 'last_review_prompt_timestamp';
  static const String _userDeclinedReviewKey = 'user_declined_review';

  Future<void> requestReviewIfAppropriate(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final bool hasDeclined = prefs.getBool(_userDeclinedReviewKey) ?? false;
      if (hasDeclined) {
        print("Review prompt skipped: User has permanently declined.");
        return;
      }

      final int? lastPromptTimestamp = prefs.getInt(_lastPromptTimestampKey);
      if (lastPromptTimestamp != null) {
        final lastPromptDate = DateTime.fromMillisecondsSinceEpoch(lastPromptTimestamp);
        if (DateTime.now().difference(lastPromptDate).inDays < 10) {
          print("Review prompt skipped: Not enough time has passed since last prompt.");
          return;
        }
      }

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Enjoying our app?'),
            content: const Text(
              'If you have a moment, please consider leaving a review. It helps us grow and improve.',
            ),
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
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
      );
    }
  }

  Future<void> _launchReviewFlow() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await _setPermanentlyDeclined();
      }
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
      );
    }
  }

  Future<void> _setRemindLater() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastPromptTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print("User chose 'Remind Me Later'. Timestamp updated.");
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
      );
    }
  }

  Future<void> _setPermanentlyDeclined() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userDeclinedReviewKey, true);
      print("User declined review. Prompts will be disabled.");
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
      );
    }
  }
}