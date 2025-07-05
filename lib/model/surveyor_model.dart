import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single Surveyor object and contains all the logic
/// for parsing data from Firestore and a local SQLite database.
class Surveyor {
  // Core Identifying Info
  final String id; // The document ID (SLA_NO)
  final String surveyorNameEn;
  final String cityEn;
  final String stateEn;
  final String? profilePictureUrl;

  // Contact Details
  final String pincode;
  final String mobileNo;
  final String emailAddr;

  // Raw address lines for display on the detail screen
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;

  // Professional Details
  final List<String> departments;
  final DateTime? licenseExpiryDate;

  // IIISLA Professional Standing
  final String? iiislaLevel;
  final String? iiislaMembershipNumber;
  final int professionalRank;

  // Geolocation Data
  final GeoPoint? geopoint;
  final double? distanceInKm; // This is a temporary, client-side calculated value

  // Monetization Rank (For future use)
  final int tierRank;

  // --- NEW: Field to track profile ownership ---
  final String? claimedByUID;

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
    required this.professionalRank,
    this.profilePictureUrl,
    this.licenseExpiryDate,
    this.iiislaLevel,
    this.iiislaMembershipNumber,
    this.geopoint,
    this.distanceInKm,
    this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    this.claimedByUID, // Add to constructor
  });

  /// Helper getter for a clean, formatted address string.
  String get fullAddress {
    return [
      addressLine1,
      addressLine2,
      addressLine3,
      '$cityEn, $stateEn - $pincode'
    ].where((s) => s != null && s.isNotEmpty).join(', ');
  }

  /// Factory constructor to parse a Firestore document into a Surveyor object.
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
      addressLine1: data['address_line1'],
      addressLine2: data['address_line2'],
      addressLine3: data['address_line3'],
      departments: List<String>.from(data['departments'] ?? []),
      licenseExpiryDate: (data['license_expiry_date'] as Timestamp?)?.toDate(),
      iiislaLevel: data['iiisla_level'],
      iiislaMembershipNumber: data['iiisla_membership_number'],
      geopoint: geopointData,
      distanceInKm: distance,
      tierRank: data['tier_rank'] ?? 99,
      professionalRank: data['professional_rank'] ?? 99,
      claimedByUID: data['claimedByUID'], // Parse the new field
    );
  }

  /// Factory constructor to create a Surveyor from a local database map.
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
      addressLine1: map['addressLine1'],
      addressLine2: map['addressLine2'],
      addressLine3: map['addressLine3'],
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
      professionalRank: map['professionalRank'],
      claimedByUID: map['claimedByUID'], // Parse from local DB
    );
  }

  /// Method to convert a Surveyor object into a map for the local SQLite database.
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
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'addressLine3': addressLine3,
      'departments': json.encode(departments),
      'licenseExpiryDate': licenseExpiryDate?.millisecondsSinceEpoch,
      'iiislaLevel': iiislaLevel,
      'iiislaMembershipNumber': iiislaMembershipNumber,
      'latitude': geopoint?.latitude,
      'longitude': geopoint?.longitude,
      'tierRank': tierRank,
      'professionalRank': professionalRank,
      'claimedByUID': claimedByUID, // Add to local DB map
    };
  }

  /// Method to convert a Surveyor object for Firestore sync.
  Map<String, dynamic> toMapForFirestore() {
    return {
      'surveyor_name_en': surveyorNameEn,
      'city_en': cityEn,
      'state_en': stateEn,
      'pincode': pincode,
      'mobile': mobileNo,
      'email': emailAddr,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'address_line3': addressLine3,
      'departments': departments,
      'license_expiry_date': licenseExpiryDate,
      'iiisla_level': iiislaLevel,
      'iiisla_membership_number': iiislaMembershipNumber,
      'position': geopoint != null ? {'geopoint': geopoint} : null,
      'tier_rank': tierRank,
      'professional_rank': professionalRank,
      'claimedByUID': claimedByUID, // Add to Firestore map
    };
  }
}
