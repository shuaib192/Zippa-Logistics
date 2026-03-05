// ============================================
// 🎓 SPLASH SCREEN (splash_screen.dart)
//
// The FIRST screen users see when they open the app.
// It shows the Zippa logo with a smooth animation,
// then checks if the user is already logged in:
// - Logged in → Go to their dashboard
// - Not logged in → Go to onboarding
//
// WHY HAVE A SPLASH SCREEN?
// 1. Shows your brand while the app loads
// 2. Gives time to check auth status, load data
// 3. Creates a professional first impression
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
    // Start the navigation after a delay
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // Wait 2.5 seconds for the animation to play
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return; // Safety check: is the widget still on screen?
    
    // Check if user is already logged in
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = await authProvider.checkAuthStatus();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      // User is logged in — go to their role-specific dashboard
      final role = authProvider.user?.role ?? 'customer';
      switch (role) {
        case 'rider':
          Navigator.pushReplacementNamed(context, '/rider-home');
          break;
        case 'vendor':
          Navigator.pushReplacementNamed(context, '/vendor-home');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/customer-home');
      }
    } else {
      // Not logged in — show onboarding
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
            // Logo with fade-in + scale animation
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
            )
                .animate()
                .fadeIn(duration: 800.ms)     // Fade from invisible to visible
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), duration: 800.ms) // Grow from small to full
                .then()                         // After previous animation...
                .shimmer(duration: 1200.ms),    // Shiny shimmer effect
            
            const SizedBox(height: 24),
            
            // App name
            Text(
              'Zippa',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0, delay: 400.ms, duration: 600.ms),
            
            const SizedBox(height: 8),
            
            // Tagline
            Text(
              'Fast, Easy and Safe',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 1,
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms, duration: 600.ms),
            
            const SizedBox(height: 48),
            
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ZippaColors.primaryLight,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 1200.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
