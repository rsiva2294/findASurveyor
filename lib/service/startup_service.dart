import 'package:find_a_surveyor/service/authentication_service.dart';
import 'package:find_a_surveyor/service/database_service.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class StartupService {
  final AuthenticationService _authenticationService;
  final FirestoreService _firestoreService;
  final DatabaseService _databaseService;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  StartupService({
    required AuthenticationService authService,
    required FirestoreService firestoreService,
    required DatabaseService databaseService,
  })  : _authenticationService = authService,
        _firestoreService = firestoreService,
        _databaseService = databaseService;

  /// This is the main method to call after a user logs in.
  Future<void> performInitialSync() async {
    final user = _authenticationService.currentUser;
    if (user == null || user.isAnonymous) {
      await _analytics.logEvent(name: 'sync_skipped_guest');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final syncFlagKey = 'hasSyncedFavorites_${user.uid}';
      final bool hasSynced = prefs.getBool(syncFlagKey) ?? false;

      if (!hasSynced) {
        print("Performing one-time favorite sync for user ${user.uid}...");
        await _analytics.logEvent(name: 'sync_started');

        final localFavorites = await _databaseService.getFavorites();

        if (localFavorites.isNotEmpty) {
          await _firestoreService.bulkSyncToFirestore(user.uid, localFavorites);
          await _analytics.logEvent(
            name: 'sync_uploaded_local',
            parameters: {'count': localFavorites.length},
          );
        }

        final cloudFavorites = await _firestoreService.getCloudFavorites(user.uid);
        await _databaseService.clearFavorites();
        await _databaseService.bulkInsertFavorites(cloudFavorites);

        await prefs.setBool(syncFlagKey, true);
        print("One-time sync complete.");
        await _analytics.logEvent(
          name: 'sync_complete',
          parameters: {'cloud_count': cloudFavorites.length},
        );
      } else {
        await _analytics.logEvent(name: 'sync_already_done');
      }
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Initial sync failed');
      await _analytics.logEvent(name: 'sync_error');
    }
  }
}