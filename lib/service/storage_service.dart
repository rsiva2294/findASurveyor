import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Uploads a profile picture for a given surveyor and returns the download URL.
  ///
  /// [surveyorId] The unique ID of the surveyor (SLA No).
  /// [imageFile] The image file picked by the user from their device.
  Future<String> uploadProfilePicture({
    required String surveyorId,
    required File imageFile,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'profile_pictures/$surveyorId/profile_$timestamp.jpg';

      final ref = _storage.ref().child(filePath);

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() => {});

      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _analytics.logEvent(
        name: 'profile_picture_uploaded',
        parameters: {
          'surveyor_id': surveyorId,
          'file_path': filePath,
          'file_size': await imageFile.length(),
        },
      );

      return downloadUrl;

    } on FirebaseException catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Profile picture upload failed');
      await FirebaseAnalytics.instance.logEvent(
        name: 'profile_picture_upload_failed',
        parameters: {'surveyor_id': surveyorId, 'error_code': e.code},
      );
      print("Firebase Storage Error: ${e.message}");
      throw Exception('Failed to upload image. Please try again.');
    }
  }
}