import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'email_screen.dart';
import 'profile_screen.dart';
import '../home/home_screen.dart';

/// OTP screen that works with both Firebase and backend verification.
/// If firebaseVerificationId is provided, uses Firebase.
/// Otherwise, uses backend OTP verification.
class OtpScreen extends StatefulWidget {
  final String target;
  final String targetType;
  final String displayTarget;
  final String? firebaseVerificationId;
  final int? firebaseResendToken;

  const OtpScreen({
    super.key,
    required this.target,
    required this.targetType,
    required this.displayTarget,
    this.firebaseVerificationId,
    this.firebaseResendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _currentVerificationId;
  bool get _isFirebaseMode => _currentVerificationId != null;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.firebaseVerificationId;
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isFirebaseMode) {
        await _verifyWithFirebase();
      } else {
        await _verifyWithBackend();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _verifyWithFirebase() async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _currentVerificationId!,
      smsCode: _otp,
    );

    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    debugPrint('Firebase sign-in OK: ${userCredential.user?.uid}');

    if (mounted) {
      final authProvider = context.read<AppAuthProvider>();
      final result = await authProvider.loginWithFirebase(
        phone: widget.target,
        firebaseUid: userCredential.user!.uid,
        firebaseToken: await userCredential.user!.getIdToken(),
      );

      setState(() => _isLoading = false);

      if (result != null && mounted) {
        _navigateToNextStep(result['next_step'] as String? ?? 'home');
      } else if (mounted) {
        _navigateToNextStep('home');
      }
    }
  }

  Future<void> _verifyWithBackend() async {
    final authProvider = context.read<AuthProvider>();
    
    Map<String, dynamic>? result;
    if (widget.targetType == 'phone') {
      result = await authProvider.verifyPhoneOtp(
        phone: widget.target,
        otp: _otp,
      );
    } else {
      result = await authProvider.verifyEmail(
        email: widget.target,
        otp: _otp,
      );
    }

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      _navigateToNextStep(result['next_step'] as String? ?? 'home');
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error!)),
      );
    }
  }

  void _navigateToNextStep(String nextStep) {
    Widget nextScreen;
    switch (nextStep) {
      case 'verify_email':
        nextScreen = const EmailScreen();
        break;
      case 'complete_profile':
        nextScreen = const ProfileScreen();
        break;
      default:
        nextScreen = const HomeScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
      (route) => false,
    );
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);

    if (_isFirebaseMode) {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.target,
        timeout: const Duration(seconds: 60),
        forceResendingToken: widget.firebaseResendToken,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message ?? 'Failed to resend')),
            );
          }
        },
        codeSent: (verificationId, _) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _currentVerificationId = verificationId;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP resent successfully')),
            );
          }
        },
        codeAutoRetrievalTimeout: (vid) => _currentVerificationId = vid,
      );
    } else {
      final authProvider = context.read<AppAuthProvider>();
      await authProvider.sendOtp(target: widget.target, targetType: widget.targetType);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text('Verification',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to\n${widget.displayTarget}',
              style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4),
            ),
            if (!_isFirebaseMode) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
                    const SizedBox(width: 8),
                    Text('Dev mode: use 123456 as OTP',
                        style: TextStyle(fontSize: 12, color: Colors.amber[900])),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 48, height: 56,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                      ),
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
                      if (value.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                      if (_otp.length == 6) _verifyOtp();
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _resendOtp,
                child: Text('Didn\'t receive the code? Resend',
                    style: TextStyle(
                        color: _isLoading ? Colors.grey : const Color(0xFF1565C0))),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}