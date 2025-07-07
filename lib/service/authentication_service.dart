
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;

  AuthenticationService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Stream<User?> get userChanges => _firebaseAuth.userChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _firebaseAuth.signInAnonymously();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Anonymous Sign-In Error: $e");
      throw Exception('Could not sign in as guest.');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User cancelled the flow

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Google Sign-In Error: $e");
      // Re-throw a user-friendly error for the UI to display
      throw Exception('A problem occurred during Google Sign-In.');
    }
  }

  Future<UserCredential?> linkGoogleToCurrentUser() async {
    try {
      // 1. Get the Google credential from the user
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User cancelled the flow

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 2. Link the credential to the current anonymous user
      return await _firebaseAuth.currentUser?.linkWithCredential(credential);
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
  }
}