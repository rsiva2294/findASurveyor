
import 'package:find_a_surveyor/service/authentication_service.dart';
import 'package:find_a_surveyor/service/database_service.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupService {
  final AuthenticationService _authenticationService;
  final FirestoreService _firestoreService;
  final DatabaseService _databaseService;

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
      // We don't sync favorites for guest users.
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final syncFlagKey = 'hasSyncedFavorites_${user.uid}';
    final bool hasSynced = prefs.getBool(syncFlagKey) ?? false;

    // Only run the migration if the flag is not set.
    if (!hasSynced) {
      print("Performing one-time favorite sync for user ${user.uid}...");

      // 1. Get local favorites from the device's SQLite database.
      final localFavorites = await _databaseService.getFavorites();

      if (localFavorites.isNotEmpty) {
        // 2. Upload the local favorites to Firestore in a batch.
        await _firestoreService.bulkSyncToFirestore(user.uid, localFavorites);
      }

      // 3. Fetch the definitive list from the cloud.
      final cloudFavorites = await _firestoreService.getCloudFavorites(user.uid);

      // 4. Clear the local cache and repopulate it with the cloud data.
      await _databaseService.clearFavorites();
      await _databaseService.bulkInsertFavorites(cloudFavorites);

      // 5. Set the flag so this migration never runs again for this user.
      await prefs.setBool(syncFlagKey, true);
      print("One-time sync complete.");
    }
  }
}