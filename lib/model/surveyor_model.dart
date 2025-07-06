
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single Surveyor object and contains all the logic
/// for parsing data from Firestore, Algolia, and a local SQLite database.
class Surveyor {
  // --- Core Identifying Info (from IRDAI) ---
  final String id; // The document ID (SLA_NO)
  final String surveyorNameEn;
  final String cityEn;
  final String stateEn;
  final String pincode;
  final String mobileNo;
  final String emailAddr;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final List<String> departments;
  final DateTime? licenseExpiryDate;
  final String? iiislaLevel;
  final String? iiislaMembershipNumber;
  final int professionalRank;

  // --- Verification & Ownership ---
  final String? claimedByUID;
  final bool isVerified;

  // --- Enrichment Data (Editable by Surveyor) ---
  final String? profilePictureUrl;
  final String? aboutMe;
  final int? surveyorSince;
  final List<String> empanelments;
  final String? altMobileNo;
  final String? altEmailAddr;
  final String? officeAddress;
  final String? websiteUrl;
  final String? linkedinUrl;

  // --- Client-Side Calculated Data ---
  final GeoPoint? geopoint;
  final double? distanceInKm;
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
    this.claimedByUID,
    this.isVerified = false,
    this.aboutMe,
    this.surveyorSince,
    this.empanelments = const [],
    this.altMobileNo,
    this.altEmailAddr,
    this.officeAddress,
    this.websiteUrl,
    this.linkedinUrl,
  });

  String get fullAddress {
    return [
      addressLine1,
      addressLine2,
      addressLine3,
      '$cityEn, $stateEn - $pincode'
    ].where((s) => s != null && s.isNotEmpty).join(', ');
  }

  factory Surveyor.fromFirestore(DocumentSnapshot doc, {double? distance}) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
    final positionMap = data['position'] as Map<String, dynamic>?;
    final geopointData = positionMap?['geopoint'] as GeoPoint?;

    return Surveyor(
      id: doc.id,
      surveyorNameEn: data['surveyor_name_en'] ?? 'No Name',
      cityEn: data['city_en'] ?? 'No City',
      stateEn: data['state_en'] ?? 'No State',
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
      professionalRank: data['professional_rank'] ?? 99,
      claimedByUID: data['claimedByUID'],
      isVerified: data['isVerified'] ?? false,
      profilePictureUrl: data['profilePictureUrl'],
      aboutMe: data['aboutMe'],
      surveyorSince: data['surveyorSince'],
      empanelments: List<String>.from(data['empanelments'] ?? []),
      altMobileNo: data['altMobileNo'],
      altEmailAddr: data['altEmailAddr'],
      officeAddress: data['officeAddress'],
      websiteUrl: data['websiteUrl'],
      linkedinUrl: data['linkedinUrl'],
      geopoint: geopointData,
      distanceInKm: distance,
      tierRank: data['tier_rank'] ?? 99,
    );
  }

  factory Surveyor.fromMap(Map<String, dynamic> map) {
    return Surveyor(
      id: map['id'],
      surveyorNameEn: map['surveyorNameEn'],
      cityEn: map['cityEn'],
      stateEn: map['stateEn'],
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
      professionalRank: map['professionalRank'],
      claimedByUID: map['claimedByUID'],
      isVerified: map['isVerified'] == 1,
      profilePictureUrl: map['profilePictureUrl'],
      aboutMe: map['aboutMe'],
      surveyorSince: map['surveyorSince'],
      empanelments: (json.decode(map['empanelments']) as List).cast<String>(),
      altMobileNo: map['altMobileNo'],
      altEmailAddr: map['altEmailAddr'],
      officeAddress: map['officeAddress'],
      websiteUrl: map['websiteUrl'],
      linkedinUrl: map['linkedinUrl'],
      geopoint: map['latitude'] != null && map['longitude'] != null
          ? GeoPoint(map['latitude'], map['longitude'])
          : null,
      tierRank: map['tierRank'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surveyorNameEn': surveyorNameEn,
      'cityEn': cityEn,
      'stateEn': stateEn,
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
      'professionalRank': professionalRank,
      'claimedByUID': claimedByUID,
      'isVerified': isVerified ? 1 : 0,
      'profilePictureUrl': profilePictureUrl,
      'aboutMe': aboutMe,
      'surveyorSince': surveyorSince,
      'empanelments': json.encode(empanelments),
      'altMobileNo': altMobileNo,
      'altEmailAddr': altEmailAddr,
      'officeAddress': officeAddress,
      'websiteUrl': websiteUrl,
      'linkedinUrl': linkedinUrl,
      'latitude': geopoint?.latitude,
      'longitude': geopoint?.longitude,
      'tierRank': tierRank,
    };
  }

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
      'claimedByUID': claimedByUID,
      'isVerified': isVerified,
      'profilePictureUrl': profilePictureUrl,
      'aboutMe': aboutMe,
      'surveyorSince': surveyorSince,
      'empanelments': empanelments,
      'altMobileNo': altMobileNo,
      'altEmailAddr': altEmailAddr,
      'officeAddress': officeAddress,
      'websiteUrl': websiteUrl,
      'linkedinUrl': linkedinUrl,
    };
  }
}
