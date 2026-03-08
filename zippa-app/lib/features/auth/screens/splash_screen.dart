// ============================================
// SPLASH SCREEN — Professional, no emojis
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = await authProvider.checkAuthStatus();
    if (!mounted) return;

    if (isLoggedIn) {
      final role = authProvider.user?.role ?? 'customer';
      switch (role) {
        case 'rider':  Navigator.pushReplacementNamed(context, '/rider-home'); break;
        case 'vendor': Navigator.pushReplacementNamed(context, '/vendor-home'); break;
        default:       Navigator.pushReplacementNamed(context, '/customer-home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZippaColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset('assets/images/logo.png', width: 120, height: 120)
                .animate()
                .fadeIn(duration: 700.ms)
                .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 700.ms)
                .then()
                .shimmer(duration: 1200.ms),

            const SizedBox(height: 28),

            // App name
            Text(
              'Zippa',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 6),

            Text(
              'Fast, Easy and Safe',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 600.ms),

            const SizedBox(height: 64),

            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ZippaColors.primaryLight.withOpacity(0.8),
                ),
              ),
            ).animate().fadeIn(delay: 1100.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
