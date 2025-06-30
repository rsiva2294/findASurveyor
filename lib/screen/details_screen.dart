import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/service/database_service.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/widget/level_chip_widget.dart';
import 'package:find_a_surveyor/widget/status_chip_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.surveyorID});
  final String surveyorID;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late FirestoreService firestoreService;
  late Future<Surveyor> futureSurveyor;

  late final DatabaseService databaseService;
  bool isFavorite = false;
  bool isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    firestoreService = Provider.of<FirestoreService>(context, listen: false);
    databaseService = Provider.of<DatabaseService>(context, listen: false);
    fetchSurveyorByID(widget.surveyorID);
    checkIfFavorite();
  }

  void fetchSurveyorByID(String surveyorID) {
    futureSurveyor = firestoreService.getSurveyorByID(surveyorID);
  }

  Future<void> checkIfFavorite() async {
    final isFav = await databaseService.isFavorite(widget.surveyorID);
    if (mounted) {
      setState(() {
        isFavorite = isFav;
      });
    }
  }

  Future<void> toggleFavorite(Surveyor surveyor) async {
    if (isTogglingFavorite) return;

    setState(() {
      isTogglingFavorite = true;
    });

    try {
      if (isFavorite) {
        await databaseService.removeFavorite(surveyor.id);
      } else {
        await databaseService.addFavorite(surveyor);
      }

      if (mounted) {
        setState(() {
          isFavorite = !isFavorite;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating favorite: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isTogglingFavorite = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showErrorSnackBar('Could not launch phone dialer.');
    }
  }

  Future<void> _sendSms(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showErrorSnackBar('Could not open messaging app.');
    }
  }

  Future<void> _sendEmail(String emailAddress) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showErrorSnackBar('Could not open email app.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Surveyor>(
        future: futureSurveyor,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Surveyor not found."));
          }

          final surveyor = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(left: 10, right: 10, bottom: 100),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        child: Text(
                          surveyor.surveyorNameEn,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            shadows: [const Shadow(blurRadius: 2, color: Colors.black45)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Transform.scale(
                        scale: 0.8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusChipWidget(
                              licenseExpiryDate: surveyor.licenseExpiryDate,
                            ),
                            const SizedBox(width: 10),
                            LevelChipWidget(level: surveyor.iiislaLevel),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        actionButtonWithLabel(
                          label: "Call",
                          icon: Icons.phone_outlined,
                          onPressed: () => _makePhoneCall(surveyor.mobileNo),
                        ),
                        actionButtonWithLabel(
                          label: "Message",
                          icon: Icons.chat_outlined,
                          onPressed: () => _sendSms(surveyor.mobileNo),
                        ),
                        actionButtonWithLabel(
                          label: "Email",
                          icon: Icons.email_outlined,
                          onPressed: () => _sendEmail(surveyor.emailAddr),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => toggleFavorite(surveyor),
                    icon: isFavorite
                        ? const Icon(Icons.favorite)
                        : const Icon(Icons.favorite_border_outlined),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined),
                  ),
                ],
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                    [
                      // TODO: Add the rest of the detail cards here (Location, License, etc.)
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text("Further details would appear here..."),
                      ),
                    ]
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
