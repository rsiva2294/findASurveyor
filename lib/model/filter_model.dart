
import 'package:cloud_firestore/cloud_firestore.dart';

// --- DATA MODELS FOR FILTERING ---

/// Represents the set of filters a user has applied.
class FilterModel {
  final String? stateName;
  final String? city;
  final String? department;
  final String? iiislaLevel;

  FilterModel({
    this.stateName,
    this.city,
    this.department,
    this.iiislaLevel,
  });

  // A helper to check if any filters are actually set
  bool get isNotEmpty => stateName != null || city != null || iiislaLevel != null || department != null;
}

/// Represents a single Department, fetched from the 'departments' collection.
class Department {
  final String id;
  final String name;

  Department({required this.id, required this.name});

  factory Department.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Department(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
    );
  }
}

/// Represents a single State and its corresponding list of cities.
class LocationData {
  final String stateName;
  final List<String> cities;
  final String stateId;

  LocationData({
    required this.stateName,
    required this.cities,
    required this.stateId,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      stateName: map['name'] ?? 'Unknown State',
      cities: List<String>.from(map['cities'] ?? []),
      stateId: map['id'] ?? '',
    );
  }
}

/// A single object that holds all the data needed to build the filter UI.
/// This is fetched once to populate the entire filter bottom sheet.
class FilterOptions {
  final List<LocationData> locations;
  final List<Department> departments;

  FilterOptions({required this.locations, required this.departments});
}