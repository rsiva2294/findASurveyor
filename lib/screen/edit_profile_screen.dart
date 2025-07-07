
import 'dart:io';

import 'package:find_a_surveyor/model/insurance_company_model.dart';
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/service/authentication_service.dart';
import 'package:find_a_surveyor/service/database_service.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/service/storage_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  // This screen receives the full surveyor object to pre-fill the form
  final Surveyor surveyor;

  const EditProfileScreen({super.key, required this.surveyor});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final FirestoreService _firestoreService;
  late final StorageService _storageService;
  late final DatabaseService _databaseService;
  late final AuthenticationService _authenticationService;
  // Controllers for all editable fields
  late final TextEditingController _aboutController;
  late final TextEditingController _surveyorSinceController;
  late final TextEditingController _altMobileController;
  late final TextEditingController _altEmailController;
  late final TextEditingController _officeAddressController;
  late final TextEditingController _websiteController;
  late final TextEditingController _linkedinController;

  // State for the multi-select dropdown
  List<InsuranceCompany> _allCompanies = [];
  List<InsuranceCompany> _selectedCompanies = [];

  // State for image picking and saving
  File? _profileImageFile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _authenticationService = Provider.of<AuthenticationService>(context, listen: false);
    // Initialize controllers with existing data from the surveyor object
    _aboutController = TextEditingController(text: widget.surveyor.aboutMe);
    _surveyorSinceController = TextEditingController(text: widget.surveyor.surveyorSince?.toString());
    _altMobileController = TextEditingController(text: widget.surveyor.altMobileNo);
    _altEmailController = TextEditingController(text: widget.surveyor.altEmailAddr);
    _officeAddressController = TextEditingController(text: widget.surveyor.officeAddress);
    _websiteController = TextEditingController(text: widget.surveyor.websiteUrl);
    _linkedinController = TextEditingController(text: widget.surveyor.linkedinUrl);

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Fetch the list of all insurance companies for the dropdown
    final companies = await _firestoreService.getInsuranceCompanies();
    if (mounted) {
      setState(() {
        _allCompanies = companies;
        // Pre-select the companies the surveyor is already empaneled with
        _selectedCompanies = _allCompanies
            .where((c) => widget.surveyor.empanelments.contains(c.id))
            .toList();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _aboutController.dispose();
    _surveyorSinceController.dispose();
    _altMobileController.dispose();
    _altEmailController.dispose();
    _officeAddressController.dispose();
    _websiteController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);

    final fileSizeInMB = await imageFile.length() / (1024 * 1024);

    if (fileSizeInMB > 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image is too large. Please select a file under 5 MB.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    setState(() {
      _profileImageFile = imageFile;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);

    try {
      String? imageUrl = widget.surveyor.profilePictureUrl;
      if (_profileImageFile != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Please wait while we upload your picture')),
          );
        }
        imageUrl = await _storageService.uploadProfilePicture(
          surveyorId: widget.surveyor.id,
          imageFile: _profileImageFile!,
        );
      }

      // Create a map of the updated data
      final updatedData = {
        'profilePictureUrl': imageUrl,
        'aboutMe': _aboutController.text.trim(),
        'surveyorSince': int.tryParse(_surveyorSinceController.text.trim()),
        'empanelments': _selectedCompanies.map((c) => c.id).toList(),
        'altMobileNo': _altMobileController.text.trim(),
        'altEmailAddr': _altEmailController.text.trim(),
        'officeAddress': _officeAddressController.text.trim(),
        'websiteUrl': _websiteController.text.trim(),
        'linkedinUrl': _linkedinController.text.trim(),
      };

      // Call the service to update the document in Firestore
      await _firestoreService.updateSurveyorProfile(widget.surveyor.id, updatedData);

      // After updating Firestore, re-fetch fresh data to ensure consistency
      final updatedSurveyor = await _firestoreService.getSurveyorByID(widget.surveyor.id);

      final isFav = await _databaseService.isFavorite(widget.surveyor.id);
      if (isFav) {
        await _databaseService.addFavorite(updatedSurveyor);
        print("Local favorite cache updated with fresh Firestore data for ${widget.surveyor.id}");
        final user = _authenticationService.currentUser;
        if (user != null && !user.isAnonymous) {
          await _firestoreService.addFavorite(user.uid, updatedSurveyor);
          print("Cloud favorite cache updated for surveyor ${widget.surveyor.id}");
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(updatedSurveyor);
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Profile Picture Section ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImageFile != null
                          ? FileImage(_profileImageFile!)
                          : (widget.surveyor.profilePictureUrl != null
                          ? NetworkImage(widget.surveyor.profilePictureUrl!)
                          : null) as ImageProvider?,
                      child: _profileImageFile == null && widget.surveyor.profilePictureUrl == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Professional Profile Section ---
              Text('Professional Profile', style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              TextFormField(controller: _aboutController, decoration: const InputDecoration(labelText: 'About Me / Bio'), maxLines: 5),
              const SizedBox(height: 16),
              TextFormField(controller: _surveyorSinceController, decoration: const InputDecoration(labelText: 'Surveyor Since (Year)'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              MultiSelectDialogField<InsuranceCompany>(
                searchable: true,
                items: _allCompanies.map((c) => MultiSelectItem(c, c.name)).toList(),
                itemsTextStyle: TextStyle(color: ColorScheme.of(context).onSurface),
                title: const Text("Select Companies"),
                selectedColor: Theme.of(context).colorScheme.primary,
                selectedItemsTextStyle: TextStyle(color: ColorScheme.of(context).onSurface),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                buttonIcon: const Icon(Icons.business_center),
                buttonText: const Text("Empaneled With"),
                onConfirm: (results) => setState(() => _selectedCompanies = results),
                initialValue: _selectedCompanies,
              ),
              const SizedBox(height: 24),

              // --- Additional Contact Info Section ---
              Text('Additional Contact Info (Optional)', style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              TextFormField(controller: _altMobileController, decoration: const InputDecoration(labelText: 'Alternate Mobile'), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextFormField(controller: _altEmailController, decoration: const InputDecoration(labelText: 'Alternate Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              TextFormField(controller: _officeAddressController, decoration: const InputDecoration(labelText: 'Office Address'), maxLines: 3),
              const SizedBox(height: 16),
              TextFormField(controller: _websiteController, decoration: const InputDecoration(labelText: 'Website URL'), keyboardType: TextInputType.url),
              const SizedBox(height: 16),
              TextFormField(controller: _linkedinController, decoration: const InputDecoration(labelText: 'LinkedIn Profile URL'), keyboardType: TextInputType.url),
            ],
          ),
        ),
      ),
    );
  }
}

