
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_a_surveyor/model/surveyor_model.dart';

class SurveyorPage{
  List<Surveyor> surveyorList;
  DocumentSnapshot? lastDocument;

  SurveyorPage({required this.surveyorList, this.lastDocument});
}