import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/widget/level_chip_widget.dart';
import 'package:find_a_surveyor/widget/status_chip_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.surveyorID});
  final String surveyorID;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late FirestoreService firestoreService;
  late Future<Surveyor> futureSurveyor;

  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    firestoreService = Provider.of<FirestoreService>(context, listen: false);
    fetchSurveyorByID(widget.surveyorID);
  }

  void fetchSurveyorByID(String surveyorID) {
    futureSurveyor = firestoreService.getSurveyorByID(surveyorID);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget actionButtonWithLabel({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          child: IconButton(onPressed: onPressed, icon: Icon(icon)),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: futureSurveyor,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }
          if (snapshot.hasData) {
            Surveyor surveyor = snapshot.data!;
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 225,
                  flexibleSpace: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                            child: Text(
                              surveyor.surveyorNameEn,
                              style: TextTheme.of(context).headlineMedium?.copyWith(
                                color: ColorScheme.of(context).onPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusChipWidget(
                                licenseExpiryDate: surveyor.licenseExpiryDate,
                              ),
                              SizedBox(width: 10),
                              LevelCustomChipWidget(level: surveyor.iiislaLevel),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              actionButtonWithLabel(
                                label: "Call",
                                icon: Icons.phone_outlined,
                                onPressed: () {},
                              ),
                              actionButtonWithLabel(
                                label: "Message",
                                icon: Icons.chat_outlined,
                                onPressed: () {},
                              ),
                              actionButtonWithLabel(
                                label: "Email",
                                icon: Icons.email_outlined,
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isFavorite = !isFavorite;
                        });
                      },
                      icon: isFavorite
                          ? const Icon(Icons.favorite)
                          : const Icon(Icons.favorite_border_outlined),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.share_outlined),
                    ),
                  ],
                ),
              ],
            );
          }
          return const Center(child: Text("Surveyor not found"));
        },
      ),
    );
  }
}
