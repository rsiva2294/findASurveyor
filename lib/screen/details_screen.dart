import 'dart:io';
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/service/authentication_service.dart';
import 'package:find_a_surveyor/service/database_service.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/service/review_service.dart';
import 'package:find_a_surveyor/utils/extension_util.dart';
import 'package:find_a_surveyor/widget/level_chip_widget.dart';
import 'package:find_a_surveyor/widget/status_chip_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.surveyorID});
  final String surveyorID;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {

  late final FirestoreService firestoreService;
  late final DatabaseService databaseService;
  late final AuthenticationService authenticationService;
  late final ReviewService reviewService;

  late Future<Surveyor> futureSurveyor;

  bool isFavorite = false;
  bool isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    firestoreService = Provider.of<FirestoreService>(context, listen: false);
    databaseService = Provider.of<DatabaseService>(context, listen: false);
    authenticationService = Provider.of<AuthenticationService>(context, listen: false);
    reviewService = Provider.of<ReviewService>(context, listen: false);
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

  /// Toggles the favorite status, syncing with both local DB and Firestore.
  Future<void> toggleFavorite(Surveyor surveyor) async {
    if (isTogglingFavorite) return;
    setState(() => isTogglingFavorite = true);

    final user = authenticationService.currentUser;
    final newFavoriteState = !isFavorite;

    try {
      if (newFavoriteState) {
        // Add to local DB first for instant UI feedback
        await databaseService.addFavorite(surveyor);
        // If user is registered (not anonymous), sync to Firestore
        if (user != null && !user.isAnonymous) {
          await firestoreService.addFavorite(user.uid, surveyor);
        }
      } else {
        // Remove from local DB first
        await databaseService.removeFavorite(surveyor.id);
        // If user is registered, sync to Firestore
        if (user != null && !user.isAnonymous) {
          await firestoreService.removeFavorite(user.uid, surveyor.id);
        }
      }

      if (mounted) {
        setState(() {
          isFavorite = newFavoriteState;
          reviewService.requestReviewIfAppropriate(context);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error updating favorite: $e');
      // If an error occurs, revert the UI state to what it was before the tap.
      if(mounted) {
        // We don't need to call the DB again, just flip the boolean back.
        setState(() {
          isFavorite = !newFavoriteState;
        });
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
      if(!mounted) return;
      reviewService.requestReviewIfAppropriate(context);
    } else {
      _showErrorSnackBar('Could not launch phone dialer.');
    }
  }

  Future<void> _openWhatsAppChat(String phoneNumber) async {
    final String whatsappNumber = '91$phoneNumber';
    final Uri whatsappUri = Uri.parse('https://wa.me/$whatsappNumber');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      if(!mounted) return;
      reviewService.requestReviewIfAppropriate(context);
    } else {
      _showErrorSnackBar('Could not open WhatsApp. Please ensure it is installed.');
    }
  }

  Future<void> _sendEmail(String emailAddress) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
      if(!mounted) return;
      reviewService.requestReviewIfAppropriate(context);
    } else {
      _showErrorSnackBar('Could not open email app.');
    }
  }

  Future<void> _sharePlainText(Surveyor surveyor) async {
    final String shareText = '''
    Contact for: ${surveyor.surveyorNameEn}
    Phone: ${surveyor.mobileNo}
    Email: ${surveyor.emailAddr}
    Shared from the Find A Surveyor app.
    ''';
    final params = ShareParams(text: shareText);
    await SharePlus.instance.share(params);
    if(!mounted) return;
    reviewService.requestReviewIfAppropriate(context);
  }

  Future<void> _shareVCard(Surveyor surveyor, {String? text}) async {
    final vCard = StringBuffer();
    vCard.writeln('BEGIN:VCARD');
    vCard.writeln('VERSION:3.0');
    vCard.writeln('FN:${surveyor.surveyorNameEn}');
    List<String> nameParts = surveyor.surveyorNameEn.split(' ');
    String firstName = '';
    String lastName = '';
    if (nameParts.isNotEmpty) {
      firstName = nameParts.first;
      if (nameParts.length > 1) {
        lastName = nameParts.sublist(1).join(' ');
      }
    }
    vCard.writeln('N:$lastName;$firstName;;;');
    vCard.writeln('TEL;TYPE=CELL:${surveyor.mobileNo}');
    vCard.writeln('EMAIL:${surveyor.emailAddr}');
    vCard.writeln('ORG:Find A Surveyor');
    vCard.writeln('END:VCARD');

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/surveyor_${surveyor.id}.vcf';
      final vcfFile = File(filePath);
      await vcfFile.writeAsString(vCard.toString());

      final params = ShareParams(
        text: text,
        files: [XFile(filePath, mimeType: 'text/vcard', name: '${surveyor.surveyorNameEn}.vcf')],
      );
      await SharePlus.instance.share(params);
      if(!mounted) return;
      reviewService.requestReviewIfAppropriate(context);
    } catch (e) {
      _showErrorSnackBar('Could not create contact card.');
    }
  }

  void _showShareOptions(BuildContext context, Surveyor surveyor) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Share Contact As...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Plain Text'),
              subtitle: const Text('Works with all apps, including WhatsApp.'),
              onTap: () {
                Navigator.of(context).pop();
                _sharePlainText(surveyor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_page_outlined),
              title: const Text('Contact Card (.vcf)'),
              subtitle: const Text('Best for email or saving to contacts.'),
              onTap: () {
                Navigator.of(context).pop();
                _shareVCard(surveyor, text: 'Here are the contact details for ${surveyor.surveyorNameEn}');
              },
            ),
          ],
        ),
      ),
    );
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

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? trailing, bool makeTitleCase = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          const SizedBox(width: 16),
          if (trailing != null)
            trailing
          else
            Flexible(
              child: Text(
                makeTitleCase ? value.toTitleCaseExt() : value,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
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
          final fullAddress = [
            '${surveyor.cityEn}, ${surveyor.stateEn} - ${surveyor.pincode}'
          ].where((s) => s.isNotEmpty).join(', ');

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
                          surveyor.surveyorNameEn.toTitleCaseExt(),
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
                          label: "WhatsApp",
                          icon: Icons.chat_outlined,
                          onPressed: () => _openWhatsAppChat(surveyor.mobileNo),
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
                    onPressed: () => _showShareOptions(context, surveyor),
                    icon: const Icon(Icons.share_outlined),
                  ),
                ],
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                    [
                      const SizedBox(height: 24),
                      _buildSectionCard(
                          title: "Contact & Location",
                          children: [
                            _buildDetailRow("Mobile", surveyor.mobileNo),
                            _buildDetailRow("Email", surveyor.emailAddr),
                            _buildDetailRow("Address", fullAddress, makeTitleCase: true),
                          ]
                      ),
                      _buildSectionCard(
                        title: "License Details",
                        children: [
                          _buildDetailRow("License Number (SLA)", surveyor.id),
                          _buildDetailRow("License Expiry", surveyor.licenseExpiryDate != null ? DateFormat.yMMMMd().format(surveyor.licenseExpiryDate!) : "N/A"),
                          _buildDetailRow("Status", "", trailing: StatusChipWidget(licenseExpiryDate: surveyor.licenseExpiryDate)),
                        ],
                      ),
                      _buildSectionCard(
                        title: "Professional Standing",
                        children: [
                          _buildDetailRow(
                           "IIISLA Level",
                            surveyor.iiislaLevel == null ? "Not Available" : surveyor.iiislaLevel!,
                            trailing: surveyor.iiislaLevel != null
                                ? LevelChipWidget(level: surveyor.iiislaLevel)
                                : null,
                          ),
                          _buildDetailRow("Membership No.", surveyor.iiislaMembershipNumber ?? "Not Available"),
                        ],
                      ),
                      _buildSectionCard(
                        title: "Specializations",
                        children: [
                          if (surveyor.departments.isNotEmpty)
                            Wrap(
                              spacing: 8.0,
                              children: surveyor.departments.map((spec) => Chip(
                                label: Text(spec.replaceAll('_', ' ').toTitleCaseExt()),
                              )).toList(),
                            )
                          else
                            const Text("No specializations listed."),
                        ],
                      ),
                      const SizedBox(height: 100),
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
