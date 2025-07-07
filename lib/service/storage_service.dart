import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a profile picture for a given surveyor and returns the download URL.
  ///
  /// [surveyorId] The unique ID of the surveyor (SLA No).
  /// [imageFile] The image file picked by the user from their device.
  Future<String> uploadProfilePicture({
    required String surveyorId,
    required File imageFile,
  }) async {
    try {
      // 1. Create a unique path for the image in Cloud Storage.
      // We use the surveyor's ID to ensure each user has their own folder,
      // and a timestamp to ensure the file name is unique if they re-upload.
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'profile_pictures/$surveyorId/profile_$timestamp.jpg';

      // 2. Create a reference to the file location.
      final ref = _storage.ref().child(filePath);

      // 3. Upload the file.
      // We can also set metadata, like the content type.
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // 4. Wait for the upload to complete.
      final snapshot = await uploadTask.whenComplete(() => {});

      // 5. Get the public download URL for the uploaded file.
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;

    } on FirebaseException catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Firebase Storage Error: ${e.message}");
      throw Exception('Failed to upload image. Please try again.');
    }
  }
}
