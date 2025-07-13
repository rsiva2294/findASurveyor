import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  AuthenticationService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  Stream<User?> get userChanges => _firebaseAuth.userChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      await _analytics.logLogin(loginMethod: 'anonymous');
      await _setTrackingIdentifiers(credential.user);
      return credential;
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Anonymous Sign-In Error: $e");
      throw Exception('Could not sign in as guest.');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      await _analytics.logLogin(loginMethod: 'google');
      await _setTrackingIdentifiers(userCredential.user);
      return userCredential;
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Google Sign-In Error: $e");
      throw Exception('A problem occurred during Google Sign-In.');
    }
  }

  Future<UserCredential?> linkGoogleToCurrentUser() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _firebaseAuth.currentUser?.linkWithCredential(credential);
      await _analytics.logEvent(name: 'link_google_account');
      await _setTrackingIdentifiers(result?.user);
      return result;
    } on FirebaseAuthException catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      if (e.code == 'credential-already-in-use') {
        throw Exception('This Google account is already linked to another user.');
      }
      print("Error linking Google account: ${e.message}");
      throw Exception('Could not link Google account.');
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();
    await _analytics.logEvent(name: 'sign_out');
  }

  // --- New helper to set analytics + crashlytics user ID ---
  Future<void> _setTrackingIdentifiers(User? user) async {
    if (user != null) {
      await FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
      await _analytics.setUserId(id: user.uid);
    }
  }
}