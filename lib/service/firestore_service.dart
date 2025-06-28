
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_a_surveyor/model/surveyor_model.dart';

class FirestoreService{

  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;

  late final CollectionReference _surveyorCollectionReference;

  FirestoreService(){
    _surveyorCollectionReference = _firestoreInstance.collection('surveyors');
  }

  Future<List<Surveyor>> getSurveyors(int limit) async{
    try{
      QuerySnapshot querySnapshot = await _surveyorCollectionReference.orderBy('surveyor_name_en').limit(limit).get();
      return querySnapshot.docs.map((doc) => Surveyor.fromFirestore(doc)).toList();
    }catch (e){
      throw Exception(e);
    }
  }
}