import 'dart:io';
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
import 'package:find_a_surveyor/service/authentication_service.dart';
import 'package:find_a_surveyor/service/database_service.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/service/review_service.dart';
import 'package:find_a_surveyor/utils/extension_util.dart';
import 'package:find_a_surveyor/widget/level_chip_widget.dart';
import 'package:find_a_surveyor/widget/status_chip_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  Future<void> toggleFavorite(Surveyor surveyor) async {
    if (isTogglingFavorite) return;

    final previousFavoriteState = isFavorite;
    setState(() {
      isFavorite = !isFavorite;
      isTogglingFavorite = true;
    });

    final user = authenticationService.currentUser;
    final bool currentFavoriteState = isFavorite;
    List<Future<void>> tasks = [];

    try {
      if (currentFavoriteState) {
        tasks.add(databaseService.addFavorite(surveyor));
        if (user != null && !user.isAnonymous) {
          tasks.add(firestoreService.addFavorite(user.uid, surveyor));
        }
      } else {
        tasks.add(databaseService.removeFavorite(surveyor.id));
        if (user != null && !user.isAnonymous) {
          tasks.add(firestoreService.removeFavorite(user.uid, surveyor.id));
        }
      }

      if (tasks.isNotEmpty) {
        await Future.wait(tasks);
      }

    } catch (e) {
      _showErrorSnackBar('Error updating favorite: $e');
      if (mounted) {
        setState(() {
          isFavorite = previousFavoriteState;
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

  void _showSignInRequiredDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Sign In Required"),
        content: const Text("To claim a profile, you must first sign in."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final userCredential = await authenticationService.linkGoogleToCurrentUser();
                if (userCredential != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You are now signed-in. Please proceed.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Sign In with Google"),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
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
  String _calculateExperience(String? surveyorSinceYearString) {
    if (surveyorSinceYearString == null || surveyorSinceYearString.isEmpty) {
      return "N/A";
    }
    try {
      final int surveyorSinceYear = int.parse(surveyorSinceYearString);
      final int currentYear = DateTime.now().year;
      final int experienceYears = currentYear - surveyorSinceYear;

      if (experienceYears < 0) {
        return "N/A"; // Or some other appropriate message for future dates
      } else if (experienceYears == 0) {
        return "Less than a year";
      } else if (experienceYears == 1) {
        return "1 year";
      } else {
        return "$experienceYears years";
      }
    } catch (e) {
      // Handle cases where surveyorSinceYearString is not a valid integer
      print("Error parsing surveyorSinceYear: $e");
      return "N/A";
    }
  }

  Widget _buildAboutSection(Surveyor surveyor) {
    if ((surveyor.aboutMe?.isNotEmpty ?? false) || surveyor.surveyorSince != null) {
      return _buildSectionCard(
        title: "About ${surveyor.surveyorNameEn.split(' ').first}",
        children: [
          if (surveyor.aboutMe != null && surveyor.aboutMe!.isNotEmpty)
            Text(
              surveyor.aboutMe!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          if (surveyor.surveyorSince != null) ...[
            const SizedBox(height: 12),
            Divider(),
            _buildDetailRow("Field Experience", "${_calculateExperience(surveyor.surveyorSince.toString())} (Since ${surveyor.surveyorSince})"),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildContactSection(Surveyor surveyor) {
    return _buildSectionCard(
      title: "Contact Details",
      children: [
        _buildDetailRow("Registered Mobile", surveyor.mobileNo),
        _buildDetailRow("Registered Email", surveyor.emailAddr),
        if (surveyor.altMobileNo?.isNotEmpty ?? false)
          _buildDetailRow("Alternate Mobile", surveyor.altMobileNo!),
        if (surveyor.altEmailAddr?.isNotEmpty ?? false)
          _buildDetailRow("Alternate Email", surveyor.altEmailAddr!),
      ],
    );
  }

  Widget _buildAddressAndWebSection(Surveyor surveyor) {
    return _buildSectionCard(
      title: surveyor.isVerified ? "Address & Web Presence" : "Address Details",
      children: [
        _buildDetailRow("Registered Address", '${surveyor.cityEn.toTitleCaseExt()}, ${surveyor.stateEn.toTitleCaseExt()}\nPincode: ${surveyor.pincode}'),
        if (surveyor.officeAddress?.isNotEmpty ?? false)
          _buildDetailRow("Office Address", surveyor.officeAddress!),
        if (surveyor.websiteUrl?.isNotEmpty ?? false)
          _buildDetailRow("Website", surveyor.websiteUrl!),
        if (surveyor.linkedinUrl?.isNotEmpty ?? false)
          _buildDetailRow("LinkedIn", surveyor.linkedinUrl!),
      ],
    );
  }

  Widget _buildProfessionalDetailsSection(Surveyor surveyor) {
    if ((surveyor.iiislaLevel != null && surveyor.iiislaLevel!.isNotEmpty) ||
        surveyor.iiislaMembershipNumber != null ||
        surveyor.empanelments.isNotEmpty) {
      return _buildSectionCard(
        title: "Professional Details",
        children: [
          if (surveyor.iiislaLevel != null && surveyor.iiislaLevel!.isNotEmpty)
            _buildDetailRow(
              "IIISLA Level",
              surveyor.iiislaLevel!,
              trailing: LevelChipWidget(level: surveyor.iiislaLevel),
            ),
          _buildDetailRow(
            "Membership No.",
            surveyor.iiislaMembershipNumber ?? "Not Available",
          ),
          if (surveyor.empanelments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text("Empaneled With", style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: surveyor.empanelments
                  .map((id) => Chip(label: Text(id.replaceAll('_', ' ').toTitleCaseExt())))
                  .toList(),
            ),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLicenseDetailsSection(Surveyor surveyor) {
    return _buildSectionCard(
      title: "License Details",
      children: [
        _buildDetailRow("License Number (SLA)", surveyor.id),
        _buildDetailRow(
          "License Expiry",
          surveyor.licenseExpiryDate != null
              ? DateFormat.yMMMMd().format(surveyor.licenseExpiryDate!)
              : "N/A",
        ),
        _buildDetailRow(
          "Status",
          "",
          trailing: StatusChipWidget(licenseExpiryDate: surveyor.licenseExpiryDate),
        ),
      ],
    );
  }


  Widget _buildSpecializationsSection(Surveyor surveyor) {
    return _buildSectionCard(
      title: "Specializations",
      children: [
        if (surveyor.departments.isNotEmpty)
          Wrap(
            spacing: 8.0,
            children: surveyor.departments
                .map((spec) => Chip(label: Text(spec.replaceAll('_', ' ').toTitleCaseExt())))
                .toList(),
          )
        else
          const Text("No specializations listed."),
      ],
    );
  }


  Widget _buildClaimProfileButton(Surveyor surveyor, User? currentUser) {
    // If the profile is already claimed, show nothing.
    if (surveyor.claimedByUID != null) {
      // If the current user is the owner, show an "Edit Profile" button instead.
      if (currentUser != null && surveyor.claimedByUID == currentUser.uid) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit My Profile'),
            onPressed: () {
              context.pushNamed(
                AppRoutes.editProfile,
                pathParameters: {'id': surveyor.id},
                extra: surveyor,
              ).then((_) {
                fetchSurveyorByID(surveyor.id);
                setState(() {});
              });
            },

          ),
        );
      }
      return const SizedBox.shrink(); // Claimed by someone else
    }

    // If the user is an anonymous guest
    if (currentUser != null && currentUser.isAnonymous) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.lock_outline, size: 18),
          label: const Text('Claim This Profile'),
          onPressed: _showSignInRequiredDialog, // Show the dialog
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.grey.shade700,
          ),
        ),
      );
    }

    // If the user is logged in with Google (or another permanent method)
    if (currentUser != null && !currentUser.isAnonymous) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Claim This Profile'),
          onPressed: () {
            // Navigate to the verification screen
            context.pushNamed(
              AppRoutes.verify,
              pathParameters: {'id': surveyor.id},
              extra: surveyor,
            );
          },
        ),
      );
    }

    // Default case if user is somehow null (should be redirected by GoRouter)
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authenticationService.userChanges,
      builder: (context, asyncSnapshot) {
        final currentUser = asyncSnapshot.data;
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  surveyor.surveyorNameEn.toTitleCaseExt(),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    shadows: [const Shadow(blurRadius: 2, color: Colors.black45)],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (surveyor.isVerified)
                                   Icon(
                                    Icons.verified,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                              ],
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
                        _buildClaimProfileButton(surveyor, currentUser),
                        const SizedBox(height: 16),
                        _buildAboutSection(surveyor),
                        const SizedBox(height: 16),
                        _buildContactSection(surveyor),
                        const SizedBox(height: 16),
                        _buildAddressAndWebSection(surveyor),
                        const SizedBox(height: 16),
                        _buildProfessionalDetailsSection(surveyor),
                        const SizedBox(height: 16),
                        _buildLicenseDetailsSection(surveyor),
                        const SizedBox(height: 16),
                        _buildSpecializationsSection(surveyor),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    );
  }
}
