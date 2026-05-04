import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import 'driver_otp_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  String _countryCode = '+91';
  String _role = 'driver';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid phone number'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final fullPhone = '$_countryCode$phone';
    final provider = context.read<DriverProvider>();
    final success = await provider.login(fullPhone, '');

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverOtpScreen(phone: fullPhone, role: _role),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<DriverProvider>().isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF004D40),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Logo Area
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                      ),
                      child: const Icon(Icons.directions_car_filled_rounded, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Local Boy',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'DRIVER & GUIDE PORTAL',
                        style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                      ),
                    ),

                    const Spacer(),

                    // Role Selector
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('I am a', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _roleCard('driver', 'Driver', Icons.directions_car_filled_rounded, '🚗')),
                        const SizedBox(width: 14),
                        Expanded(child: _roleCard('guide', 'Guide', Icons.tour_rounded, '🗺️')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Phone Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            decoration: BoxDecoration(
                              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                            ),
                            child: Text(
                              _countryCode,
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1.5, fontWeight: FontWeight.w500),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Phone number',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 16),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OTP Button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1B5E20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Get OTP', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'By continuing, you agree to our Terms of Service',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String value, String label, IconData icon, String emoji) {
    final isSelected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.08)])
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
