import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Surveyor.fromFirestore(DocumentSnapshot doc, {double? distance}) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

    // Safely extract the geopoint from the 'position' map in Firestore
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
}