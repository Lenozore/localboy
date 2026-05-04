import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phoneController = TextEditingController();
  String _countryCode = '+91';
  bool _isLoading = false;
  bool _useFirebase = true; // Will fallback to backend if Firebase fails

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'country': '🇮🇳 India'},
    {'code': '+1', 'country': '🇺🇸 USA'},
    {'code': '+44', 'country': '🇬🇧 UK'},
    {'code': '+61', 'country': '🇦🇺 Australia'},
    {'code': '+971', 'country': '🇦🇪 UAE'},
    {'code': '+65', 'country': '🇸🇬 Singapore'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    final fullPhone = '$_countryCode$phone';
    setState(() => _isLoading = true);

    if (_useFirebase) {
      try {
        await _sendOtpViaFirebase(fullPhone);
      } catch (e) {
        debugPrint('Firebase failed, falling back to backend OTP: $e');
        _useFirebase = false;
        await _sendOtpViaBackend(fullPhone);
      }
    } else {
      await _sendOtpViaBackend(fullPhone);
    }
  }

  Future<void> _sendOtpViaFirebase(String fullPhone) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: fullPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verify on Android
        debugPrint('Auto verification completed');
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('Firebase verification failed: ${e.message}');
        if (mounted) {
          setState(() => _isLoading = false);
          // Fallback to backend OTP if Firebase fails
          _useFirebase = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Firebase error: ${e.message}. Using SMS fallback.'),
              backgroundColor: Colors.orange,
            ),
          );
          _sendOtpViaBackend(fullPhone);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        debugPrint('Firebase OTP sent! verificationId: $verificationId');
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                target: fullPhone,
                targetType: 'phone',
                displayTarget: '$_countryCode ${_phoneController.text.trim()}',
                firebaseVerificationId: verificationId,
                firebaseResendToken: resendToken,
              ),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> _sendOtpViaBackend(String fullPhone) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.sendOtp(
        target: fullPhone,
        targetType: 'phone',
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              target: fullPhone,
              targetType: 'phone',
              displayTarget: '$_countryCode ${_phoneController.text.trim()}',
            ),
          ),
        );
      } else if (mounted && authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error!)),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e')),
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
            const Text(
              'Enter your\nphone number',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll send you a verification code via SMS',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _countryCode,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      borderRadius: BorderRadius.circular(12),
                      items: _countryCodes.map((item) {
                        return DropdownMenuItem(
                          value: item['code'],
                          child: Text(
                            '${item['country']} ${item['code']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _countryCode = value);
                      },
                      selectedItemBuilder: (context) {
                        return _countryCodes.map((item) {
                          return Center(
                            child: Text(item['code']!,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    style: const TextStyle(fontSize: 18, letterSpacing: 1.2),
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send OTP',
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
