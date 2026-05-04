import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'phone_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1565C0),
              Color(0xFF0D47A1),
              Color(0xFF002171),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo & Branding
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.explore,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Local Boy',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore Like a Local',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),

                const Spacer(flex: 2),

                // Phone Number Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PhoneScreen()),
                      );
                    },
                    icon: const Icon(Icons.phone_android, size: 22),
                    label: const Text(
                      'Continue with Phone',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleGoogleSignIn(context),
                    icon: Image.network(
                      'https://developers.google.com/identity/images/g-logo.png',
                      height: 22,
                      width: 22,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                    ),
                    label: const Text(
                      'Sign in with Google',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Terms
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    // Google Sign-In requires google_sign_in package
    // For now, show a message that it needs to be configured
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-In requires Google Cloud setup. Use phone login for now.'),
      ),
    );
  }
}
