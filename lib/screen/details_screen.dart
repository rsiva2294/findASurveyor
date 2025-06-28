import 'package:flutter/material.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.surveyorID});
  final String surveyorID;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Surveyor Details"),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined),
            onPressed: (){

            },
          ),
        ],
      ),
    );
  }
}
