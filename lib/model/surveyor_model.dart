import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Surveyor {
  // Core Identifying Info
  final String id;
  final String surveyorNameEn;
  final String cityEn;
  final String stateEn;
  final String? profilePictureUrl;

  // Contact Details
  final String pincode;
  final String mobileNo;
  final String emailAddr;

  // Professional Details
  final List<String> departments;
  final DateTime? licenseExpiryDate;

  // IIISLA Professional Standing
  final String? iiislaLevel;
  final String? iiislaMembershipNumber;

  // Geolocation Data
  final GeoPoint? geopoint;
  final double? distanceInKm;

  // Monetization Rank (For future use)
  final int tierRank;

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
    this.profilePictureUrl,
    this.licenseExpiryDate,
    this.iiislaLevel,
    this.iiislaMembershipNumber,
    this.geopoint,
    this.distanceInKm,
  });

  // --- Methods for firestore database ---
  // Factory constructor to parse a Firestore document
  factory Surveyor.fromFirestore(DocumentSnapshot doc, {double? distance}) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
    final positionMap = data['position'] as Map<String, dynamic>?;
    final geopointData = positionMap?['geopoint'] as GeoPoint?;

    return Surveyor(
      id: doc.id,
      surveyorNameEn: data['surveyor_name_en'] ?? 'No Name',
      cityEn: data['city_en'] ?? 'No City',
      stateEn: data['state_en'] ?? 'No State',
      profilePictureUrl: data['profilePictureUrl'],
      pincode: data['pincode'] ?? '',
      mobileNo: data['mobile'] ?? '',
      emailAddr: data['email'] ?? '',
      departments: List<String>.from(data['departments'] ?? []),
      licenseExpiryDate: (data['license_expiry_date'] as Timestamp?)?.toDate(),
      iiislaLevel: data['iiisla_level'],
      iiislaMembershipNumber: data['iiisla_membership_number'],
      geopoint: geopointData,
      distanceInKm: distance,
      tierRank: data['tier_rank'] ?? 99,
    );
  }

  Map<String, dynamic> toMapForFirestore() {
    return {
      // We use the clean field names that our Flutter app uses
      'surveyor_name_en': surveyorNameEn,
      'city_en': cityEn,
      'state_en': stateEn,
      'pincode': pincode,
      'mobile': mobileNo,
      'email': emailAddr,
      'departments': departments, // Firestore handles lists directly
      'license_expiry_date': licenseExpiryDate, // Firestore handles DateTime/Timestamp
      'iiisla_level': iiislaLevel,
      'iiisla_membership_number': iiislaMembershipNumber,
      // We create the 'position' map that our geoqueries expect
      'position': geopoint != null ? {
        'geopoint': geopoint,
        // We can add the geohash here if needed, but geopoint is sufficient for this operation
      } : null,
      'tier_rank': tierRank,
      // Note: We DO NOT save 'distanceInKm' as it's a calculated value.
    };
  }

  // --- Methods for local SQLite database ---

  // Factory constructor to create a Surveyor from a local database map
  factory Surveyor.fromMap(Map<String, dynamic> map) {
    return Surveyor(
      id: map['id'],
      surveyorNameEn: map['surveyorNameEn'],
      cityEn: map['cityEn'],
      stateEn: map['stateEn'],
      profilePictureUrl: map['profilePictureUrl'],
      pincode: map['pincode'],
      mobileNo: map['mobileNo'],
      emailAddr: map['emailAddr'],
      // Decode the JSON string back into a List<String>
      departments: (json.decode(map['departments']) as List).cast<String>(),
      licenseExpiryDate: map['licenseExpiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['licenseExpiryDate'])
          : null,
      iiislaLevel: map['iiislaLevel'],
      iiislaMembershipNumber: map['iiislaMembershipNumber'],
      geopoint: map['latitude'] != null && map['longitude'] != null
          ? GeoPoint(map['latitude'], map['longitude'])
          : null,
      tierRank: map['tierRank'],
    );
  }

  // Method to convert a Surveyor object into a map for the local database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surveyorNameEn': surveyorNameEn,
      'cityEn': cityEn,
      'stateEn': stateEn,
      'profilePictureUrl': profilePictureUrl,
      'pincode': pincode,
      'mobileNo': mobileNo,
      'emailAddr': emailAddr,
      // SQLite can't store lists, so we encode it as a JSON string
      'departments': json.encode(departments),
      // SQLite can't store DateTime, so we store it as an integer (milliseconds)
      'licenseExpiryDate': licenseExpiryDate?.millisecondsSinceEpoch,
      'iiislaLevel': iiislaLevel,
      'iiislaMembershipNumber': iiislaMembershipNumber,
      // SQLite can't store GeoPoint, so we store lat and lng as separate numbers
      'latitude': geopoint?.latitude,
      'longitude': geopoint?.longitude,
      'tierRank': tierRank,
    };
  }
}