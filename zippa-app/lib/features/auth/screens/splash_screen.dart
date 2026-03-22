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
  bool _isBiometricFailed = false;

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = await authProvider.checkAuthStatus();
    if (!mounted) return;

    if (isLoggedIn) {
      if (authProvider.isBiometricEnabled) {
        final authenticated = await authProvider.authenticateWithBiometrics();
        if (authenticated) {
          _gotoHome(authProvider);
        } else {
          setState(() => _isBiometricFailed = true);
        }
      } else {
        _gotoHome(authProvider);
      }
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  void _gotoHome(AuthProvider authProvider) {
    final role = authProvider.user?.role ?? 'customer';
    switch (role) {
      case 'rider':  Navigator.pushReplacementNamed(context, '/rider-home'); break;
      case 'vendor': Navigator.pushReplacementNamed(context, '/vendor-home'); break;
      default:       Navigator.pushReplacementNamed(context, '/customer-home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZippaColors.primaryDark,
      body: Stack(
        children: [
          Center(
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

                if (!_isBiometricFailed)
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
          if (_isBiometricFailed)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Authentication Required',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _navigateAfterSplash,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZippaColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Try Again'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Provider.of<AuthProvider>(context, listen: false).logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    child: const Text('Login with Password', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ).animate().fadeIn(),
            ),
        ],
      ),
    );
  }
}
