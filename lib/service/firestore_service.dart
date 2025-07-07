import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_a_surveyor/model/filter_model.dart';
import 'package:find_a_surveyor/model/insurance_company_model.dart';
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/page/surveyor_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class FirestoreService {
  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  late final CollectionReference _surveyorCollectionReference;
  late final GeoCollectionReference _geoCollectionReference;
  late final CollectionReference _locationsCollectionReference;
  late final CollectionReference _departmentsCollectionReference;
  late final CollectionReference _usersCollectionReference;
  late final CollectionReference _insuranceCompanyCollection;

  FirestoreService() {
    _surveyorCollectionReference = _firestoreInstance.collection('surveyors');
    _geoCollectionReference = GeoCollectionReference(_surveyorCollectionReference);
    _locationsCollectionReference = _firestoreInstance.collection('locations');
    _departmentsCollectionReference = _firestoreInstance.collection('departments');
    _usersCollectionReference = _firestoreInstance.collection('users');
    _insuranceCompanyCollection = _firestoreInstance.collection('insurance_companies');
  }

  Future<void> setSurveyorAsClaimed(String surveyorId, String userId) async {
    try {
      await _surveyorCollectionReference.doc(surveyorId).update({
        'claimedByUID': userId,
        'isVerified': true,
      });
      await _analytics.logEvent(name: 'surveyor_claimed', parameters: {
        'surveyor_id': surveyorId,
        'user_id': userId,
      });
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Error setting surveyor as claimed: $e");
      throw Exception('Could not finalize profile claim. Please try again.');
    }
  }

  Future<SurveyorPage> getSurveyors({required int limit, DocumentSnapshot? startAfterDoc}) async {
    try {
      Query query = _surveyorCollectionReference
          .orderBy('professional_rank')
          .orderBy('surveyor_name_en')
          .limit(limit);

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }
      QuerySnapshot querySnapshot = await query.get();

      final surveyorList = querySnapshot.docs.map((doc) => Surveyor.fromFirestore(doc)).toList();
      final lastDoc = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

      await _analytics.logEvent(name: 'load_surveyors', parameters: {
        'limit': limit,
        'result_count': surveyorList.length,
      });

      return SurveyorPage(surveyorList: surveyorList, lastDocument: lastDoc);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      debugPrint("Error fetching surveyors: $e");
      throw Exception('Failed to load data. Please check your connection.');
    }
  }

  Future<Surveyor> getSurveyorByID(String id) async {
    try {
      DocumentSnapshot documentSnapshot = await _surveyorCollectionReference.doc(id).get();
      await _analytics.logEvent(name: 'get_surveyor_by_id', parameters: {'surveyor_id': id});
      return Surveyor.fromFirestore(documentSnapshot);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      debugPrint("Error fetching surveyor by id: $e");
      throw Exception('Failed to load data. Please check your connection.');
    }
  }

  Future<List<Surveyor>> searchSurveyors(String query) async {
    if (query.isEmpty) {
      return [];
    }
    try {
      QuerySnapshot querySnapshot = await _surveyorCollectionReference
          .where('search_keywords', arrayContains: query.toLowerCase())
          .limit(15)
          .get();
      await _analytics.logSearch(searchTerm: query);
      return querySnapshot.docs.map((doc) => Surveyor.fromFirestore(doc)).toList();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      debugPrint("Error searching surveyors: $e");
      throw Exception('Failed to load data. Please check your connection.');
    }
  }

  Future<FilterOptions> getFilterOptions() async {
    try {
      final results = await Future.wait([
        _getLocations(),
        _getDepartments(),
      ]);

      await _analytics.logEvent(name: 'get_filter_options');

      return FilterOptions(
        locations: results[0] as List<LocationData>,
        departments: results[1] as List<Department>,
      );
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Error fetching filter options: $e");
      throw Exception('Could not load filter data.');
    }
  }

  Future<List<LocationData>> _getLocations() async {
    try {
      final statesSnapshot = await _locationsCollectionReference.doc('_all_states').get();
      final data = statesSnapshot.data() as Map<String, dynamic>?;

      if (!statesSnapshot.exists || data == null || data['stateList'] == null) {
        return [];
      }

      final stateListData = data['stateList'] as List;

      return stateListData
          .map((stateMap) => LocationData.fromMap(stateMap as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack);
      rethrow;
    }
  }

  Future<List<Department>> _getDepartments() async {
    try {
      final snapshot = await _departmentsCollectionReference.orderBy('sort_order').get();
      return snapshot.docs.map((doc) => Department.fromFirestore(doc)).toList();
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack);
      rethrow;
    }
  }

  Future<List<Surveyor>> getFilteredSurveyors({required FilterModel filters}) async {
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
      await _analytics.logEvent(name: 'filter_surveyors', parameters: {
        'filters': filterKeys.join(',')
      });
      return querySnapshot.docs.map((doc) => Surveyor.fromFirestore(doc)).toList();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
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

      final List<GeoDocumentSnapshot> results = await _geoCollectionReference.fetchWithinWithDistance(
        center: center,
        radiusInKm: radiusInKm,
        field: 'position',
        geopointFrom: geopointFrom,
      );

      final List<Surveyor> surveyors = results.map((geoDoc) {
        return Surveyor.fromFirestore(geoDoc.documentSnapshot, distance: geoDoc.distanceFromCenterInKm);
      }).toList();

      await _analytics.logEvent(name: 'get_nearby_surveyors', parameters: {
        'latitude': lat,
        'longitude': lng,
        'radius_km': radiusInKm,
        'result_count': surveyors.length,
      });

      return surveyors;
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      debugPrint("Error fetching nearby surveyors: $e");
      throw Exception('Could not fetch nearby results.');
    }
  }

  Future<void> addFavorite(String userId, Surveyor surveyor) async {
    try {
      await _usersCollectionReference
          .doc(userId)
          .collection('favorites')
          .doc(surveyor.id)
          .set(surveyor.toMapForFirestore());
      await _analytics.logEvent(name: 'cloud_add_favorite', parameters: {
        'user_id': userId,
        'surveyor_id': surveyor.id,
      });
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Error adding favorite to Firestore: $e");
      throw Exception("Could not save favorite. Please try again.");
    }
  }

  Future<void> removeFavorite(String userId, String surveyorId) async {
    try {
      await _usersCollectionReference
          .doc(userId)
          .collection('favorites')
          .doc(surveyorId)
          .delete();
      await _analytics.logEvent(name: 'cloud_remove_favorite', parameters: {
        'user_id': userId,
        'surveyor_id': surveyorId,
      });
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Error removing favorite from Firestore: $e");
      throw Exception("Could not remove favorite. Please try again.");
    }
  }

  Future<List<Surveyor>> getCloudFavorites(String userId) async {
    try {
      final snapshot = await _usersCollectionReference
          .doc(userId)
          .collection('favorites')
          .get();
      await _analytics.logEvent(name: 'get_cloud_favorites', parameters: {
        'user_id': userId,
        'count': snapshot.docs.length,
      });
      return snapshot.docs.map((doc) => Surveyor.fromFirestore(doc)).toList();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Error fetching favorites from Firestore: $e");
      throw Exception("Could not load your saved favorites.");
    }
  }

  Future<void> bulkSyncToFirestore(String userId, List<Surveyor> localFavorites) async {
    try {
      final batch = _firestoreInstance.batch();
      final favoritesCollection = _usersCollectionReference.doc(userId).collection('favorites');

      for (final surveyor in localFavorites) {
        final docRef = favoritesCollection.doc(surveyor.id);
        batch.set(docRef, surveyor.toMapForFirestore());
      }
      await batch.commit();
      await _analytics.logEvent(name: 'bulk_sync_favorites', parameters: {
        'user_id': userId,
        'count': localFavorites.length,
      });
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Error syncing local favorites to Firestore: $e");
      throw Exception("Could not sync your saved favorites.");
    }
  }

  Future<List<InsuranceCompany>> getInsuranceCompanies() async {
    try {
      final snapshot = await _insuranceCompanyCollection.orderBy('name').get();
      await _analytics.logEvent(name: 'get_insurance_companies');
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return InsuranceCompany(id: doc.id, name: data?['name'] ?? '');
      }).toList();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Error fetching insurance companies: $e");
      return [];
    }
  }

  Future<void> updateSurveyorProfile(String surveyorId, Map<String, dynamic> data) async {
    try {
      await _surveyorCollectionReference.doc(surveyorId).update(data);
      await _analytics.logEvent(name: 'update_surveyor_profile', parameters: {
        'surveyor_id': surveyorId,
      });
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      print("Error updating surveyor profile: $e");
      throw Exception("Could not save profile changes. Please try again.");
    }
  }
}