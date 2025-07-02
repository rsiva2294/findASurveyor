import 'package:find_a_surveyor/service/authentication_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Helper function to launch URLs
Future<void> _launchURL(BuildContext context, String urlString) async {
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleSignIn(Future<dynamic> Function() signInMethod) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await signInMethod();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context, listen: false);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand, // Make stack fill the screen
        children: [
          Container(color: Colors.white),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.45, 1.0],
                colors: [
                  Colors.black.withAlpha(230),
                  Colors.black.withAlpha(153),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Layer 3: Main Content Column
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // This empty container with a flexible factor pushes the logo down.
                  const Spacer(flex: 2),
                  Image.asset('assets/icon/app_icon_transparent.png', height: 150),
                  const SizedBox(height: 32),
                  Text(
                    'Find A Surveyor',
                    style: textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The official directory for IRDAI-licensed surveyors',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  // This spacer fills the gap and pushes the login buttons to the bottom.
                  const Spacer(flex: 3),
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    Column(
                      children: [
                        // Using InkWell with a Container to create a custom button feel
                        InkWell(
                          onTap: () => _handleSignIn(authService.signInWithGoogle),
                          child: Image.asset(
                            'assets/icon/android_neutral_sq_ctn@4x.png',
                            height: 40,
                          ),
                        ),
                      ],
                    ),
                  const Spacer(flex: 1),
                  const _TermsAndPrivacyText(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Layer 4: Skip Button (Now on top of everything else)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: TextButton(
              onPressed: () {
                _handleSignIn(authService.signInAnonymously);
              },
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsAndPrivacyText extends StatelessWidget {
  const _TermsAndPrivacyText();
  @override
  Widget build(BuildContext context) {
    const termsUrl = 'https://irdai-surveyor-app.web.app/terms_of_service.html';
    const privacyUrl = 'https://irdai-surveyor-app.web.app/privacy_policy.html';

    return Column(
      children: [
        Text(
          'By continuing, you agree to our',
          style: TextStyle(color: Colors.white.withAlpha(153)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _launchURL(context, termsUrl),
              child: const Text(
                'Terms of Service',
                style: TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
            const Text('&', style: TextStyle(color: Colors.white)),
            TextButton(
              onPressed: () => _launchURL(context, privacyUrl),
              child: const Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
