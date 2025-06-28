
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/page/surveyor_page.dart';
import 'package:flutter/foundation.dart';

class FirestoreService{

  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;

  late final CollectionReference _surveyorCollectionReference;

  FirestoreService(){
    _surveyorCollectionReference = _firestoreInstance.collection('surveyors');
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
}