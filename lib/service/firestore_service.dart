
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_a_surveyor/model/filter_model.dart';
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/page/surveyor_page.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class FirestoreService{

  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;

  late final CollectionReference _surveyorCollectionReference;
  late final GeoCollectionReference _geoCollectionReference;
  late final CollectionReference _locationsCollectionReference;
  late final CollectionReference _departmentsCollectionReference;
  late final CollectionReference _usersCollectionReference;

  FirestoreService(){
    _surveyorCollectionReference = _firestoreInstance.collection('surveyors');
    _geoCollectionReference = GeoCollectionReference(_surveyorCollectionReference);
    _locationsCollectionReference = _firestoreInstance.collection('locations');
    _departmentsCollectionReference = _firestoreInstance.collection('departments');
    _usersCollectionReference = _firestoreInstance.collection('users');
  }

  Future<SurveyorPage> getSurveyors({required int limit, DocumentSnapshot? startAfterDoc}) async {
    try {
      Query query = _surveyorCollectionReference.orderBy('sl_no').limit(limit);

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }
      QuerySnapshot querySnapshot = await query.get();

      final surveyorList = querySnapshot.docs.map((doc) => Surveyor.fromFirestore(doc)).toList();

      final lastDoc = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

      return SurveyorPage(surveyorList: surveyorList, lastDocument: lastDoc);
    } catch (e) {
      debugPrint("Error fetching surveyors: $e");
      throw Exception('Failed to load data. Please check your connection.');
    }
  }

  Future<Surveyor> getSurveyorByID(String id) async {
    try{
      DocumentSnapshot documentSnapshot = await _surveyorCollectionReference.doc(id).get();
      return Surveyor.fromFirestore(documentSnapshot);
    }catch (e){
      debugPrint("Error fetching surveyor by id: $e");
      throw Exception('Failed to load data. Please check your connection.');
    }
  }

  Future<List<Surveyor>> searchSurveyors(String query) async {
    if(query.isEmpty){
      return [];
    }
    try{
      QuerySnapshot querySnapshot = await _surveyorCollectionReference.where('search_keywords', arrayContains: query.toLowerCase()).limit(15).get();
      return querySnapshot.docs.map((doc) => Surveyor.fromFirestore(doc)).toList();
    }catch (e){
      debugPrint("Error searching surveyors: $e");
      throw Exception('Failed to load data. Please check your connection.');
    }
  }

  /// Fetches all the data needed to populate the filter options UI in one go.
  Future<FilterOptions> getFilterOptions() async {
    try {
      // Fetch all departments and locations in parallel for efficiency
      final results = await Future.wait([
        _getLocations(),
        _getDepartments(),
      ]);

      return FilterOptions(
        locations: results[0] as List<LocationData>,
        departments: results[1] as List<Department>,
      );
    } catch (e) {
      print("Error fetching filter options: $e");
      throw Exception('Could not load filter data.');
    }
  }

  // Helper method to fetch and structure all location data
  Future<List<LocationData>> _getLocations() async {
    final statesSnapshot = await _locationsCollectionReference.doc('_all_states').get();
    final data = statesSnapshot.data() as Map<String, dynamic>?;

    if (!statesSnapshot.exists || data == null) return [];

    final stateListData = data['stateList'] as List;
    final List<Future<LocationData>> locationFutures = [];

    for (var stateMap in stateListData) {
      final stateInfo = stateMap as Map<String, dynamic>;
      final stateId = stateInfo['id'] as String;
      final stateName = stateInfo['name'] as String;

      // Create a future for each city document fetch
      final future = _locationsCollectionReference.doc(stateId).get().then((cityDoc) {
        final cityData = cityDoc.data() as Map<String, dynamic>?;
        final cities = List<String>.from(cityData?['cities'] ?? []);
        return LocationData(stateName: stateName, cities: cities, stateId: stateId);
      });
      locationFutures.add(future);
    }

    // Wait for all the city fetches to complete
    return await Future.wait(locationFutures);
  }

  // Helper method to fetch all departments
  Future<List<Department>> _getDepartments() async {
    final snapshot = await _departmentsCollectionReference.orderBy('sort_order').get();
    return snapshot.docs.map((doc) => Department.fromFirestore(doc)).toList();
  }

  // This method now fetches all matching documents at once, without pagination.
  Future<List<Surveyor>> getFilteredSurveyors({
    required FilterModel filters,
  }) async {
    Query query = _surveyorCollectionReference;

    final List<String> filterKeys = [];
    String? cleanKey(String? value) => value?.toLowerCase().replaceAll(' ', '_');

    final stateKey = cleanKey(filters.stateName);
    final cityKey = cleanKey(filters.city);
    final levelKey = cleanKey(filters.iiislaLevel);

    List<String?> parts = [
      if (stateKey != null) 'state_$stateKey',
      if (cityKey != null) 'city_$cityKey',
      if (levelKey != null) 'level_$levelKey'
    ];

    if (parts.isNotEmpty) {
      filterKeys.add(parts.where((p) => p != null).join('#'));
    }

    if (filterKeys.isNotEmpty) {
      query = query.where('filter_keys', arrayContains: filterKeys.first);
    }

    try {
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Surveyor.fromFirestore(doc)).toList();
    } catch (e) {
      print("Firestore Query Error: $e");
      throw Exception('Failed to execute filtered query.');
    }
  }

  Future<List<Surveyor>> getNearbySurveyors({
    required double lat,
    required double lng,
    double radiusInKm = 10,
  }) async {
    try {
      final center = GeoFirePoint(GeoPoint(lat, lng));

      GeoPoint geopointFrom(Object? data) {
        final map = data as Map<String, dynamic>;
        final position = map['position'] as Map<String, dynamic>;
        return position['geopoint'] as GeoPoint;
      }

      // Use the one-time fetch method
      final List<GeoDocumentSnapshot> results = await _geoCollectionReference.fetchWithinWithDistance(
        center: center,
        radiusInKm: radiusInKm,
        field: 'position',
        geopointFrom: geopointFrom,
      );

      // Map the results to our Surveyor model
      final List<Surveyor> surveyors = results.map((geoDoc) {
        return Surveyor.fromFirestore(geoDoc.documentSnapshot, distance: geoDoc.distanceFromCenterInKm);
      }).toList();

      return surveyors;

    } catch (e) {
      debugPrint("Error fetching nearby surveyors: $e");
      throw Exception('Could not fetch nearby results.');
    }
  }

  // --- FAVORITES SYNC METHODS ---

  /// Adds a surveyor to a user's 'favorites' subcollection in Firestore.
  Future<void> addFavorite(String userId, Surveyor surveyor) async {
    try {
      // We store a copy of the surveyor data for efficient retrieval.
      // The toMapForFirestore() method prepares the data correctly for Firestore.
      await _usersCollectionReference
          .doc(userId)
          .collection('favorites')
          .doc(surveyor.id)
          .set(surveyor.toMapForFirestore());
    } catch (e) {
      print("Error adding favorite to Firestore: $e");
      throw Exception("Could not save favorite. Please try again.");
    }
  }

  /// Removes a surveyor from a user's 'favorites' subcollection.
  Future<void> removeFavorite(String userId, String surveyorId) async {
    try {
      await _usersCollectionReference
          .doc(userId)
          .collection('favorites')
          .doc(surveyorId)
          .delete();
    } catch (e) {
      print("Error removing favorite from Firestore: $e");
      throw Exception("Could not remove favorite. Please try again.");
    }
  }

  /// Fetches the user's complete list of favorites from Firestore.
  Future<List<Surveyor>> getCloudFavorites(String userId) async {
    try {
      final snapshot = await _usersCollectionReference
          .doc(userId)
          .collection('favorites')
          .get();
      return snapshot.docs.map((doc) => Surveyor.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching favorites from Firestore: $e");
      throw Exception("Could not load your saved favorites.");
    }
  }

  /// For the one-time migration of existing local favorites to the cloud.
  Future<void> bulkSyncToFirestore(String userId, List<Surveyor> localFavorites) async {
    try {
      final batch = _firestoreInstance.batch();
      final favoritesCollection = _usersCollectionReference.doc(userId).collection('favorites');

      for (final surveyor in localFavorites) {
        final docRef = favoritesCollection.doc(surveyor.id);
        batch.set(docRef, surveyor.toMapForFirestore());
      }
      await batch.commit();
    } catch (e) {
      print("Error syncing local favorites to Firestore: $e");
      throw Exception("Could not sync your saved favorites.");
    }
  }
}