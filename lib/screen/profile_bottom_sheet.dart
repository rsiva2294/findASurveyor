
import 'package:feedback/feedback.dart';
import 'package:find_a_surveyor/service/authentication_service.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/service/review_service.dart';
import 'package:find_a_surveyor/utils/snackbar_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileSheet extends StatelessWidget {
  final BuildContext parentContext;
  final VoidCallback onLoginSuccess;

  const ProfileSheet({super.key, required this.parentContext, required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context, listen: false);
    final user = authService.currentUser;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Material(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileHeader(user: user),
                const Divider(height: 24),
                _ProfileMenuList(
                  parentContext: parentContext,
                  user: user,
                  onLoginSuccess: onLoginSuccess,
                ),
                const SizedBox(height: 8),
                const _ProfileFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User? user;

  const _ProfileHeader({this.user});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasGooglePhoto = user?.photoURL != null;
    final bool isAnonymous = user == null || user!.isAnonymous;

    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: hasGooglePhoto ? NetworkImage(user!.photoURL!) : null,
          child: !hasGooglePhoto ? const Icon(Icons.person, size: 28) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAnonymous ? 'Guest User' : '${user?.providerData.first.displayName}',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (user?.email != null)
                Text(user!.email!, style: textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _ProfileMenuList extends StatelessWidget {
  final BuildContext parentContext;
  final User? user;
  final VoidCallback onLoginSuccess;

  const _ProfileMenuList({
    required this.parentContext,
    required this.user,
    required this.onLoginSuccess,
  });

  void _launchURL(String urlString) {
    final Uri url = Uri.parse(urlString);
    launchUrl(url, mode: LaunchMode.externalApplication).then((success) {
      if (!success) {
        SnackbarUtil.showSnackBar(message: 'Could not launch $urlString');
      }
    });
  }

  void _showFeedbackSheet() {
    final firestoreService = Provider.of<FirestoreService>(parentContext, listen: false);
    final authService = Provider.of<AuthenticationService>(parentContext, listen: false);

    BetterFeedback.of(parentContext).show((feedback) async {
      // Immediately close the feedback UI so the user is free
      Navigator.of(parentContext).pop();
      // Small delay ensures smooth visual transition
      await Future.delayed(const Duration(milliseconds: 100));
      SnackbarUtil.showSnackBar(message: "Submitting feedback, please wait");

      try {
        await firestoreService.submitFeedback(
          feedbackText: feedback.text,
          screenshot: feedback.screenshot,
          userId: authService.currentUser?.uid,
        );
        SnackbarUtil.showSnackBar(
          message: "Thank you for your feedback!",
          backgroundColor: Colors.green,
        );
      } catch (e) {
        SnackbarUtil.showSnackBar(
          message: "Failed to submit feedback!",
          backgroundColor: Colors.red,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context, listen: false);
    final reviewService = Provider.of<ReviewService>(context, listen: false);
    final bool isAnonymous = user == null || user!.isAnonymous;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text("About the Developer"),
          onTap: () {
            Navigator.of(context).pop();
            Future.delayed(const Duration(milliseconds: 250), () {
              _launchURL('https://www.linkedin.com/in/sivakaminathan-muthusamy');
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.feedback_outlined),
          title: const Text("Submit Feedback"),
          onTap: () {
            Navigator.of(context).pop();
            Future.delayed(const Duration(milliseconds: 250), _showFeedbackSheet);
          },
        ),
        ListTile(
          leading: const Icon(Icons.star_outline),
          title: const Text("Rate this App"),
          onTap: () {
            Navigator.of(context).pop();
            Future.delayed(const Duration(milliseconds: 250), () {
              reviewService.requestReviewIfAppropriate(parentContext);
            });
          },
        ),
        const Divider(),
        isAnonymous
            ? ListTile(
          leading: const Icon(Icons.login),
          title: const Text("Sign In / Create Account"),
          onTap: () {
            Navigator.of(context).pop();
            Future.delayed(const Duration(milliseconds: 250), onLoginSuccess);
          },
        )
            : ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Logout", style: TextStyle(color: Colors.red)),
          onTap: () {
            Navigator.of(context).pop();
            Future.delayed(const Duration(milliseconds: 250), () {
              authService.signOut();
              SnackbarUtil.showSnackBar(message: 'You have been signed out.');
            });
          },
        ),
      ],
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(onPressed: () {}, child: const Text("Privacy Policy", style: TextStyle(fontSize: 12))),
        const Text("•", style: TextStyle(fontSize: 12)),
        TextButton(onPressed: () {}, child: const Text("Terms of Service", style: TextStyle(fontSize: 12))),
      ],
    );
  }
}
