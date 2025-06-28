import 'package:cloud_firestore/cloud_firestore.dart';

class Surveyor {
  // Use non-nullable types where possible for safety
  final String id; // The document ID (SLA_NO)
  final String surveyorNameEn;
  final String cityEn;
  final String stateEn;
  final String pincode;
  final String mobileNo;
  final String emailAddr;
  final List<String> departments;
  final int tierRank;
  final GeoPoint? location; // Firestore has a native GeoPoint type
  final String? geohash;
  final String? profilePictureUrl;
  final DateTime? licenseExpiryDate;

  Surveyor({
    required this.id,
    required this.surveyorNameEn,
    required this.cityEn,
    required this.stateEn,
    required this.pincode,
    required this.mobileNo,
    required this.emailAddr,
    required this.departments,
    required this.tierRank,
    this.location,
    this.geohash,
    this.profilePictureUrl,
    this.licenseExpiryDate,
  });

  // This factory constructor is our parser. It takes a DocumentSnapshot
  // from Firestore and creates a clean Surveyor object.
  factory Surveyor.fromFirestore(DocumentSnapshot doc) {
    // Get the data from the snapshot
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

    GeoPoint? locationData;
    if (data['location'] != null && data['location'] is Map) {
      final locationMap = data['location'] as Map<String, dynamic>;
      locationData = GeoPoint(
        locationMap['lat'] ?? 0.0,
        locationMap['lng'] ?? 0.0,
      );
    }

    return Surveyor(
      id: doc.id,
      // Use the clean field names from our Firestore schema
      surveyorNameEn: data['surveyor_name_en'] ?? 'No Name Provided',
      cityEn: data['city_en'] ?? '',
      stateEn: data['state_en'] ?? '',
      pincode: data['pincode'] ?? '',
      mobileNo: data['mobile'] ?? '',
      emailAddr: data['email'] ?? '',
      // Ensure we handle the data types correctly
      departments: List<String>.from(data['departments'] ?? []),
      tierRank: data['tier_rank'] ?? 99,
      location: locationData,
      geohash: data['geohash'],
      profilePictureUrl: data['profilePictureUrl'],
      // Safely convert the Firestore Timestamp to a Dart DateTime
      licenseExpiryDate: (data['license_expiry_date'] as Timestamp?)?.toDate(),
    );
  }
}