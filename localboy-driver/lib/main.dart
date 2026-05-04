import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/driver_provider.dart';
import 'screens/auth/driver_login_screen.dart';
import 'screens/dashboard/driver_dashboard.dart';

void main() {
  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: MaterialApp(
        title: 'Local Boy Driver',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const DriverSplash(),
      ),
    );
  }
}

class DriverSplash extends StatefulWidget {
  const DriverSplash({super.key});

  @override
  State<DriverSplash> createState() => _DriverSplashState();
}

class _DriverSplashState extends State<DriverSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _animController.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final provider = context.read<DriverProvider>();
    final isLoggedIn = await provider.checkAuth();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => isLoggedIn ? const DriverDashboard() : const DriverLoginScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF004D40)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
                  ),
                  child: const Icon(Icons.directions_car_filled_rounded, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
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
                        'DRIVER & GUIDE',
                        style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 28, height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white.withValues(alpha: 0.6),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
