import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LocalBoyApp());
}

class LocalBoyApp extends StatelessWidget {
  const LocalBoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'Local Boy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const SplashRouter(),
      ),
    );
  }
}

/// Checks auth status and routes to the appropriate screen
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1)); // Brief splash

    if (!mounted) return;

    final authProvider = context.read<AppAuthProvider>();
    final isLoggedIn = await authProvider.checkAuthStatus();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const HomeScreen() : const WelcomeScreen(),
      ),
    );
  }

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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore,
                size: 72,
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'Local Boy',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                color: Colors.white70,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}