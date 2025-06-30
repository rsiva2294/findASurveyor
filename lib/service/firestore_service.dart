
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/page/surveyor_page.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class FirestoreService{

  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;

  late final CollectionReference _surveyorCollectionReference;
  late final GeoCollectionReference _geoCollectionReference;

  FirestoreService(){
    _surveyorCollectionReference = _firestoreInstance.collection('surveyors');
    _geoCollectionReference = GeoCollectionReference(_surveyorCollectionReference);
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

  Future<List<Surveyor>> getNearbySurveyors({
    required double lat,
    required double lng,
    double radiusInKm = 10,
  }) async {
    try {
      final geo = GeoCollectionReference(_surveyorCollectionReference);
      final center = GeoFirePoint(GeoPoint(lat, lng));

      GeoPoint geopointFrom(Object? data) {
        final map = data as Map<String, dynamic>;
        final position = map['position'] as Map<String, dynamic>;
        return position['geopoint'] as GeoPoint;
      }

      // Use the one-time fetch method
      final List<GeoDocumentSnapshot> results = await geo.fetchWithinWithDistance(
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
}