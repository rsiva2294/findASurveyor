
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class VerificationScreen extends StatefulWidget {
  final Surveyor surveyor;
  const VerificationScreen({super.key, required this.surveyor});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _auth = FirebaseAuth.instance;
  late final FirestoreService _firestoreService;

  // State variables for the verification flow
  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;
  String? _errorMessage;

  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
  }

  /// Initiates the phone number verification process.
  Future<void> _verifyPhoneNumber() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91${widget.surveyor.mobileNo}',

      verificationCompleted: (PhoneAuthCredential credential) async {
        print("Verification completed automatically.");
        await _linkAndFinalize(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        print("Verification failed: ${e.message}");
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Verification failed. Please try again. (${e.message})";
          });
        }
      },

      codeSent: (String verificationId, int? resendToken) {
        print("Code sent. Verification ID: $verificationId");
        if (mounted) {
          setState(() {
            _isLoading = false;
            _codeSent = true;
            _verificationId = verificationId;
          });
        }
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        print("Auto-retrieval timed out.");
      },
    );
  }

  /// Submits the user-entered OTP to link the credential.
  Future<void> _submitOTP() async {
    if (_verificationId == null || _otpController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: _otpController.text.trim(),
    );

    await _linkAndFinalize(credential);
  }

  /// The final step: links the credential and updates the Firestore document.
  Future<void> _linkAndFinalize(PhoneAuthCredential credential) async {
    try {
      await _auth.currentUser?.linkWithCredential(credential);

      await _firestoreService.setSurveyorAsClaimed(
        widget.surveyor.id,
        _auth.currentUser!.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile claimed successfully!'), backgroundColor: Colors.green),
        );
        // Pop twice to go back past the details screen to the main list
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      print("Error linking credential: ${e.message}");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Invalid OTP or an error occurred. (${e.message})";
        });
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Claim Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Verify you are ${widget.surveyor.surveyorNameEn}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'A verification code will be sent to the phone number on record:',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '+91 ${widget.surveyor.mobileNo}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            if (!_codeSent)
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyPhoneNumber,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Send Verification Code'),
              )
            else
              Column(
                children: [
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Enter 6-Digit Code',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitOTP,
                    child: _isLoading ? const CircularProgressIndicator() : const Text('Verify and Claim Profile'),
                  ),
                ],
              ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              )
          ],
        ),
      ),
    );
  }
}